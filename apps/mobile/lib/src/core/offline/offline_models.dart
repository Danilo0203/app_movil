part of '../../../main.dart';

enum SyncStatus { pending, syncing, synced, error }

extension SyncStatusX on SyncStatus {
  String get value => switch (this) {
    SyncStatus.pending => 'pending',
    SyncStatus.syncing => 'syncing',
    SyncStatus.synced => 'synced',
    SyncStatus.error => 'error',
  };

  String get label => switch (this) {
    SyncStatus.pending => 'Pendiente',
    SyncStatus.syncing => 'Sincronizando',
    SyncStatus.synced => 'Sincronizada',
    SyncStatus.error => 'Error',
  };
}

SyncStatus parseSyncStatus(String? value) {
  return switch (value) {
    'syncing' => SyncStatus.syncing,
    'synced' => SyncStatus.synced,
    'error' => SyncStatus.error,
    _ => SyncStatus.pending,
  };
}

class LocalSubmissionRecord {
  LocalSubmissionRecord({
    required this.localId,
    required this.userId,
    required this.challengeId,
    required this.status,
    required this.syncStatus,
    required this.pendingComplete,
    required this.createdAt,
    required this.updatedAt,
    this.remoteId,
    this.lastError,
  });

  final String localId;
  final int userId;
  final int challengeId;
  final int? remoteId;
  final String status;
  final SyncStatus syncStatus;
  final bool pendingComplete;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'local_id': localId,
    'user_id': userId,
    'challenge_id': challengeId,
    'remote_id': remoteId,
    'status': status,
    'sync_status': syncStatus.value,
    'pending_complete': pendingComplete ? 1 : 0,
    'last_error': lastError,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory LocalSubmissionRecord.fromMap(Map<String, Object?> map) {
    return LocalSubmissionRecord(
      localId: map['local_id']! as String,
      userId: map['user_id']! as int,
      challengeId: map['challenge_id']! as int,
      remoteId: map['remote_id'] as int?,
      status: map['status']! as String,
      syncStatus: parseSyncStatus(map['sync_status'] as String?),
      pendingComplete: (map['pending_complete'] as int? ?? 0) == 1,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }
}

class LocalEvidenceRecord {
  LocalEvidenceRecord({
    required this.localId,
    required this.submissionLocalId,
    required this.itemCode,
    required this.localFilePath,
    required this.syncStatus,
    required this.clientRequestId,
    required this.createdAt,
    required this.updatedAt,
    this.remotePhotoPath,
    this.lastError,
  });

  final String localId;
  final String submissionLocalId;
  final String itemCode;
  final String localFilePath;
  final String? remotePhotoPath;
  final SyncStatus syncStatus;
  final String clientRequestId;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'local_id': localId,
    'submission_local_id': submissionLocalId,
    'item_code': itemCode,
    'local_file_path': localFilePath,
    'remote_photo_path': remotePhotoPath,
    'sync_status': syncStatus.value,
    'client_request_id': clientRequestId,
    'last_error': lastError,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory LocalEvidenceRecord.fromMap(Map<String, Object?> map) {
    return LocalEvidenceRecord(
      localId: map['local_id']! as String,
      submissionLocalId: map['submission_local_id']! as String,
      itemCode: map['item_code']! as String,
      localFilePath: map['local_file_path']! as String,
      remotePhotoPath: map['remote_photo_path'] as String?,
      syncStatus: parseSyncStatus(map['sync_status'] as String?),
      clientRequestId: map['client_request_id']! as String,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }
}

class SyncQueueItem {
  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityLocalId,
    required this.operationType,
    required this.payloadJson,
    required this.clientRequestId,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.filePath,
    this.lastError,
  });

  final int id;
  final String entityType;
  final String entityLocalId;
  final String operationType;
  final String payloadJson;
  final String? filePath;
  final String clientRequestId;
  final SyncStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;

  Map<String, dynamic> get payload =>
      jsonDecode(payloadJson) as Map<String, dynamic>;

  factory SyncQueueItem.fromMap(Map<String, Object?> map) {
    return SyncQueueItem(
      id: map['id']! as int,
      entityType: map['entity_type']! as String,
      entityLocalId: map['entity_local_id']! as String,
      operationType: map['operation_type']! as String,
      payloadJson: map['payload_json']! as String,
      filePath: map['file_path'] as String?,
      clientRequestId: map['client_request_id']! as String,
      status: parseSyncStatus(map['status'] as String?),
      retryCount: map['retry_count']! as int,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at']! as String),
    );
  }
}

class CachedListResult<T> {
  CachedListResult({
    required this.items,
    required this.fromCache,
    this.cachedAt,
  });

  final List<T> items;
  final bool fromCache;
  final DateTime? cachedAt;
}

class CachedValueResult<T> {
  CachedValueResult({
    required this.value,
    required this.fromCache,
    this.cachedAt,
  });

  final T? value;
  final bool fromCache;
  final DateTime? cachedAt;
}
