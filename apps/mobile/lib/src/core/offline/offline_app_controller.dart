part of '../../../main.dart';

class OfflineAppController extends ChangeNotifier with WidgetsBindingObserver {
  OfflineAppController._()
    : databaseService = LocalDatabaseService.instance,
      connectivityService = ConnectivityService(),
      queueRepository = OfflineSyncQueueRepository(
        LocalDatabaseService.instance,
      ) {
    syncManager = SyncManager(
      databaseService: databaseService,
      queueRepository: queueRepository,
      connectivityService: connectivityService,
    );
  }

  static final OfflineAppController instance = OfflineAppController._();

  final LocalDatabaseService databaseService;
  final ConnectivityService connectivityService;
  final OfflineSyncQueueRepository queueRepository;
  late final SyncManager syncManager;
  String? _baseUrl;
  AuthSession? _session;
  bool _initialized = false;
  int _pendingCount = 0;

  bool get isOnline => connectivityService.isOnline;
  bool get isSyncing => syncManager.isRunning;
  int get pendingCount => _pendingCount;
  DateTime? rankingCachedAt;

  Future<void> initialize({required String baseUrl}) async {
    _baseUrl = baseUrl;
    await databaseService.database;
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    await connectivityService.initialize(baseUrl);
    connectivityService.addListener(_onConnectivityChanged);
    _pendingCount = await queueRepository.pendingCount();
    _initialized = true;
    notifyListeners();
  }

  void updateSession(AuthSession? session) {
    _session = session;
    unawaited(refreshSyncState());
  }

  Future<void> refreshSyncState() async {
    _pendingCount = await queueRepository.pendingCount();
    notifyListeners();
    await triggerSync();
  }

  Future<CachedListResult<ChallengeModel>> loadChallenges() async {
    final session = _requireSession();
    final api = _apiForSession(session);
    try {
      var challenges = await api.listChallenges();
      if (challenges.isEmpty) {
        await api.seedChallenges();
        challenges = await api.listChallenges();
      }
      await databaseService.cacheChallenges(challenges);

      final submissions = await api.mySubmissions();
      await _mergeRemoteSubmissions(session.userId, submissions);
      await refreshSyncState();
      return CachedListResult(
        items: challenges,
        fromCache: false,
        cachedAt: DateTime.now(),
      );
    } catch (_) {
      return databaseService.readCachedChallenges();
    }
  }

  Future<List<SubmissionModel>> loadSubmissions() async {
    final session = _requireSession();
    final records = await databaseService.listSubmissionsForUser(
      session.userId,
    );
    final results = <SubmissionModel>[];
    for (final record in records) {
      final evidences = await databaseService.listEvidencesForSubmission(
        record.localId,
      );
      results.add(SubmissionModel.fromLocal(record, evidences));
    }
    return results;
  }

  Future<SubmissionModel> loadOrCreateSubmission(
    ChallengeModel challenge,
  ) async {
    final session = _requireSession();
    var record = await databaseService.findLatestSubmissionForChallenge(
      userId: session.userId,
      challengeId: challenge.id,
    );
    if (record == null) {
      final now = DateTime.now();
      final localId = _generateId('sub');
      record = LocalSubmissionRecord(
        localId: localId,
        userId: session.userId,
        challengeId: challenge.id,
        remoteId: null,
        status: 'IN_PROGRESS',
        syncStatus: SyncStatus.pending,
        pendingComplete: false,
        lastError: null,
        createdAt: now,
        updatedAt: now,
      );
      await databaseService.upsertSubmission(record);
      await queueRepository.enqueueOrReplace(
        entityType: 'submission',
        entityLocalId: localId,
        operationType: 'create',
        payload: {'challengeId': challenge.id},
        clientRequestId: _generateId('create-sub'),
      );
      await refreshSyncState();
    }
    return _buildSubmissionModel(record);
  }

  Future<SubmissionModel> captureEvidence({
    required ChallengeModel challenge,
    required ChallengeItem item,
    required File sourceFile,
  }) async {
    final submission = await loadOrCreateSubmission(challenge);
    final persistedFile = await _persistImage(
      sourceFile,
      folder: 'evidences',
      prefix: '${submission.localId}_${item.code}',
    );
    final existing = await databaseService.findEvidence(
      submissionLocalId: submission.localId,
      itemCode: item.code,
    );
    final now = DateTime.now();
    final evidence = LocalEvidenceRecord(
      localId: existing?.localId ?? _generateId('evi'),
      submissionLocalId: submission.localId,
      itemCode: item.code,
      localFilePath: persistedFile.path,
      remotePhotoPath: existing?.remotePhotoPath,
      syncStatus: SyncStatus.pending,
      clientRequestId: existing?.clientRequestId ?? _generateId('upload'),
      lastError: null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await databaseService.upsertEvidence(evidence);
    await databaseService.upsertSubmission(
      LocalSubmissionRecord(
        localId: submission.localId,
        userId: _requireSession().userId,
        challengeId: challenge.id,
        remoteId: submission.remoteId,
        status: submission.status,
        syncStatus: SyncStatus.pending,
        pendingComplete: submission.pendingComplete,
        lastError: null,
        createdAt: submission.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await queueRepository.enqueueOrReplace(
      entityType: 'evidence',
      entityLocalId: evidence.localId,
      operationType: 'upload',
      payload: {'submissionLocalId': submission.localId, 'itemCode': item.code},
      filePath: persistedFile.path,
      clientRequestId: evidence.clientRequestId,
    );
    await refreshSyncState();
    return loadOrCreateSubmission(challenge);
  }

  Future<SubmissionModel> completeSubmission(ChallengeModel challenge) async {
    final submission = await loadOrCreateSubmission(challenge);
    final missing = challenge.items.where((item) {
      return !submission.evidences.any(
        (evidence) => evidence.itemCode == item.code,
      );
    }).toList();
    if (missing.isNotEmpty) {
      throw Exception(
        'Checklist incompleto. Faltan ${missing.length} evidencias.',
      );
    }
    final now = DateTime.now();
    await databaseService.upsertSubmission(
      LocalSubmissionRecord(
        localId: submission.localId,
        userId: _requireSession().userId,
        challengeId: challenge.id,
        remoteId: submission.remoteId,
        status: 'COMPLETED',
        syncStatus: SyncStatus.pending,
        pendingComplete: true,
        lastError: null,
        createdAt: submission.createdAt ?? now,
        updatedAt: now,
      ),
    );
    await queueRepository.enqueueOrReplace(
      entityType: 'submission',
      entityLocalId: submission.localId,
      operationType: 'complete',
      payload: {'submissionLocalId': submission.localId},
      clientRequestId: _generateId('complete'),
    );
    await refreshSyncState();
    return loadOrCreateSubmission(challenge);
  }

  Future<CachedValueResult<UserProfileModel>> loadProfile() async {
    final session = _requireSession();
    final api = _apiForSession(session);
    try {
      final profile = await api.myProfile();
      await databaseService.cacheProfile(session.userId, profile);
      await refreshSyncState();
      return CachedValueResult(
        value: profile,
        fromCache: false,
        cachedAt: DateTime.now(),
      );
    } catch (_) {
      return databaseService.readCachedProfile(session.userId);
    }
  }

  Future<UserProfileModel> saveProfileOffline({
    required UserProfileModel base,
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    final session = _requireSession();
    final updated = base.copyWith(
      name: name,
      email: email,
      phone: phone.isEmpty ? null : phone,
      address: address.isEmpty ? null : address,
      syncStatus: SyncStatus.pending,
    );
    await databaseService.cacheProfile(session.userId, updated);
    await queueRepository.enqueueOrReplace(
      entityType: 'profile',
      entityLocalId: '${session.userId}',
      operationType: 'update',
      payload: {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      },
      clientRequestId: _generateId('profile'),
    );
    await refreshSyncState();
    return updated;
  }

  Future<UserProfileModel> saveAvatarOffline(File sourceFile) async {
    final session = _requireSession();
    final cached = await loadProfile();
    final base =
        cached.value ??
        UserProfileModel(
          id: session.userId,
          name: session.userName,
          email: session.userEmail,
        );
    final persisted = await _persistImage(
      sourceFile,
      folder: 'avatars',
      prefix: 'avatar_${session.userId}',
    );
    final updated = base.copyWith(
      localAvatarPath: persisted.path,
      syncStatus: SyncStatus.pending,
    );
    await databaseService.cacheProfile(session.userId, updated);
    await queueRepository.enqueueOrReplace(
      entityType: 'profile',
      entityLocalId: '${session.userId}',
      operationType: 'avatar',
      payload: {'userId': session.userId},
      filePath: persisted.path,
      clientRequestId: _generateId('avatar'),
    );
    await refreshSyncState();
    return updated;
  }

  Future<CachedListResult<Map<String, dynamic>>> loadRanking() async {
    final api = ApiClient(baseUrl: _requireBaseUrl());
    try {
      final rows = await api.ranking();
      await databaseService.cacheRanking(rows);
      rankingCachedAt = DateTime.now();
      notifyListeners();
      return CachedListResult(
        items: rows,
        fromCache: false,
        cachedAt: rankingCachedAt,
      );
    } catch (_) {
      final cached = await databaseService.readCachedRanking();
      rankingCachedAt = cached.cachedAt;
      notifyListeners();
      return cached;
    }
  }

  Future<void> triggerSync() async {
    final session = _session;
    final baseUrl = _baseUrl;
    if (session == null || baseUrl == null) return;
    await syncManager.run(
      baseUrl: baseUrl,
      session: session,
      onChanged: () async {
        unawaited(_refreshPendingCount());
      },
    );
    await _refreshPendingCount();
  }

  Future<SubmissionModel> _buildSubmissionModel(
    LocalSubmissionRecord record,
  ) async {
    final evidences = await databaseService.listEvidencesForSubmission(
      record.localId,
    );
    return SubmissionModel.fromLocal(record, evidences);
  }

  Future<void> _mergeRemoteSubmissions(
    int userId,
    List<SubmissionModel> submissions,
  ) async {
    for (final submission in submissions) {
      final existing = await databaseService.findSubmissionByRemoteId(
        submission.id,
      );
      final localId = existing?.localId ?? 'remote-${submission.id}';
      await databaseService.upsertSubmission(
        LocalSubmissionRecord(
          localId: localId,
          userId: userId,
          challengeId: submission.challengeId,
          remoteId: submission.id,
          status: submission.status,
          syncStatus: SyncStatus.synced,
          pendingComplete: false,
          lastError: null,
          createdAt: submission.createdAt ?? DateTime.now(),
          updatedAt:
              submission.updatedAt ?? submission.createdAt ?? DateTime.now(),
        ),
      );
      for (final evidence in submission.evidences) {
        final existingEvidence = await databaseService.findEvidence(
          submissionLocalId: localId,
          itemCode: evidence.itemCode,
        );
        await databaseService.upsertEvidence(
          LocalEvidenceRecord(
            localId: existingEvidence?.localId ?? _generateId('remote-evi'),
            submissionLocalId: localId,
            itemCode: evidence.itemCode,
            localFilePath: existingEvidence?.localFilePath ?? '',
            remotePhotoPath: evidence.photoPath,
            syncStatus: SyncStatus.synced,
            clientRequestId:
                existingEvidence?.clientRequestId ?? _generateId('remote'),
            lastError: null,
            createdAt: existingEvidence?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<File> _persistImage(
    File sourceFile, {
    required String folder,
    required String prefix,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(dir.path, folder));
    await targetDir.create(recursive: true);
    final rawExtension = p.extension(sourceFile.path);
    final extension = rawExtension.isEmpty ? '.jpg' : rawExtension;
    final target = File(
      p.join(
        targetDir.path,
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );
    return sourceFile.copy(target.path);
  }

  ApiClient _apiForSession(AuthSession session) =>
      ApiClient(baseUrl: _requireBaseUrl(), token: session.accessToken);

  String _requireBaseUrl() {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      throw StateError('OfflineAppController no inicializado.');
    }
    return baseUrl;
  }

  AuthSession _requireSession() {
    final session = _session;
    if (session == null) {
      throw StateError('No hay sesión activa.');
    }
    return session;
  }

  String _generateId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_requireSession().userId}';

  void _onConnectivityChanged() {
    notifyListeners();
    unawaited(triggerSync());
  }

  Future<void> _refreshPendingCount() async {
    _pendingCount = await queueRepository.pendingCount();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(triggerSync());
    }
  }
}
