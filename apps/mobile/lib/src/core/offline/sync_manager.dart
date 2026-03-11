part of '../../../main.dart';

class SyncManager {
  SyncManager({
    required LocalDatabaseService databaseService,
    required OfflineSyncQueueRepository queueRepository,
    required ConnectivityService connectivityService,
  }) : _databaseService = databaseService,
       _queueRepository = queueRepository,
       _connectivityService = connectivityService;

  final LocalDatabaseService _databaseService;
  final OfflineSyncQueueRepository _queueRepository;
  final ConnectivityService _connectivityService;
  bool _running = false;

  bool get isRunning => _running;

  Future<void> run({
    required String baseUrl,
    required AuthSession session,
    required VoidCallback onChanged,
  }) async {
    if (_running) return;
    await _connectivityService.refresh(baseUrl, notify: false);
    if (!_connectivityService.isOnline) return;

    _running = true;
    onChanged();
    final api = ApiClient(baseUrl: baseUrl, token: session.accessToken);

    try {
      while (true) {
        final items = await _queueRepository.pendingItems();
        if (items.isEmpty) break;
        final item = items.first;
        await _queueRepository.markSyncing(item.id);
        onChanged();
        try {
          await _processItem(api, session, item);
          await _queueRepository.markDone(item.id);
        } catch (error) {
          await _queueRepository.markError(
            item.id,
            error.toString().replaceFirst('Exception: ', ''),
            item.retryCount + 1,
          );
          break;
        } finally {
          onChanged();
        }
      }
    } finally {
      _running = false;
      onChanged();
    }
  }

  Future<void> _processItem(
    ApiClient api,
    AuthSession session,
    SyncQueueItem item,
  ) async {
    switch ('${item.entityType}:${item.operationType}') {
      case 'submission:create':
        await _processSubmissionCreate(api, session, item);
        return;
      case 'evidence:upload':
        await _processEvidenceUpload(api, item);
        return;
      case 'submission:complete':
        await _processSubmissionComplete(api, item);
        return;
      case 'profile:update':
        await _processProfileUpdate(api, session, item);
        return;
      case 'profile:avatar':
        await _processProfileAvatar(api, session, item);
        return;
    }
  }

  Future<void> _processSubmissionCreate(
    ApiClient api,
    AuthSession session,
    SyncQueueItem item,
  ) async {
    final localId = item.entityLocalId;
    final submission = await _databaseService.findSubmissionByLocalId(localId);
    if (submission == null) return;
    if (submission.remoteId != null) return;

    final challengeId = item.payload['challengeId'] as int;
    final remote = await api.createSubmission(
      challengeId,
      clientRequestId: item.clientRequestId,
    );
    final synced = LocalSubmissionRecord(
      localId: submission.localId,
      userId: session.userId,
      challengeId: submission.challengeId,
      remoteId: remote.id,
      status: submission.status,
      syncStatus: submission.pendingComplete
          ? SyncStatus.pending
          : SyncStatus.synced,
      pendingComplete: submission.pendingComplete,
      lastError: null,
      createdAt: submission.createdAt,
      updatedAt: DateTime.now(),
    );
    await _databaseService.upsertSubmission(synced);
  }

  Future<void> _processEvidenceUpload(ApiClient api, SyncQueueItem item) async {
    final evidence = await _databaseService.findEvidence(
      submissionLocalId: item.payload['submissionLocalId'] as String,
      itemCode: item.payload['itemCode'] as String,
    );
    if (evidence == null) return;

    final submission = await _databaseService.findSubmissionByLocalId(
      evidence.submissionLocalId,
    );
    if (submission == null) return;
    if (submission.remoteId == null) {
      throw Exception('Submission remota no disponible todavía.');
    }

    final file = File(evidence.localFilePath);
    if (!await file.exists()) {
      throw Exception('No se encontró la evidencia local para sincronizar.');
    }

    final result = await api.uploadEvidence(
      submissionId: submission.remoteId!,
      itemCode: evidence.itemCode,
      file: file,
      clientRequestId: item.clientRequestId,
    );
    await _databaseService.upsertEvidence(
      LocalEvidenceRecord(
        localId: evidence.localId,
        submissionLocalId: evidence.submissionLocalId,
        itemCode: evidence.itemCode,
        localFilePath: evidence.localFilePath,
        remotePhotoPath: result['photoPath']?.toString(),
        syncStatus: SyncStatus.synced,
        clientRequestId: evidence.clientRequestId,
        lastError: null,
        createdAt: evidence.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _processSubmissionComplete(
    ApiClient api,
    SyncQueueItem item,
  ) async {
    final submission = await _databaseService.findSubmissionByLocalId(
      item.entityLocalId,
    );
    if (submission == null) return;
    if (submission.remoteId == null) {
      throw Exception('Submission remota no disponible todavía.');
    }

    await api.completeSubmission(
      submission.remoteId!,
      clientRequestId: item.clientRequestId,
    );
    await _databaseService.upsertSubmission(
      LocalSubmissionRecord(
        localId: submission.localId,
        userId: submission.userId,
        challengeId: submission.challengeId,
        remoteId: submission.remoteId,
        status: 'COMPLETED',
        syncStatus: SyncStatus.synced,
        pendingComplete: false,
        lastError: null,
        createdAt: submission.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _processProfileUpdate(
    ApiClient api,
    AuthSession session,
    SyncQueueItem item,
  ) async {
    final payload = item.payload;
    final updated = await api.updateMyProfile(
      name: payload['name']?.toString(),
      email: payload['email']?.toString(),
      phone: payload['phone']?.toString(),
      address: payload['address']?.toString(),
      clientRequestId: item.clientRequestId,
    );
    await _databaseService.cacheProfile(
      session.userId,
      updated.copyWith(
        syncStatus: SyncStatus.synced,
        localAvatarPath: updated.localAvatarPath,
      ),
    );
  }

  Future<void> _processProfileAvatar(
    ApiClient api,
    AuthSession session,
    SyncQueueItem item,
  ) async {
    final filePath = item.filePath;
    if (filePath == null) return;
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception(
        'No se encontró la foto de perfil local para sincronizar.',
      );
    }
    final updated = await api.uploadMyAvatar(
      file,
      clientRequestId: item.clientRequestId,
    );
    final cached = await _databaseService.readCachedProfile(session.userId);
    final merged = (cached.value ?? updated).copyWith(
      avatarUrl: updated.avatarUrl,
      localAvatarPath: null,
      syncStatus: SyncStatus.pending,
    );
    await _databaseService.cacheProfile(session.userId, merged);
  }
}
