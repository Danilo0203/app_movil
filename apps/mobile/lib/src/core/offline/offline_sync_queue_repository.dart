part of '../../../main.dart';

class OfflineSyncQueueRepository {
  OfflineSyncQueueRepository(this._db);

  final LocalDatabaseService _db;

  Future<void> enqueueOrReplace({
    required String entityType,
    required String entityLocalId,
    required String operationType,
    required Map<String, dynamic> payload,
    required String clientRequestId,
    String? filePath,
  }) async {
    final database = await _db.database;
    final existing = await database.query(
      'sync_queue',
      where:
          'entity_type = ? AND entity_local_id = ? AND operation_type = ? AND status != ?',
      whereArgs: [
        entityType,
        entityLocalId,
        operationType,
        SyncStatus.synced.value,
      ],
      limit: 1,
    );
    final values = {
      'entity_type': entityType,
      'entity_local_id': entityLocalId,
      'operation_type': operationType,
      'payload_json': jsonEncode(payload),
      'file_path': filePath,
      'client_request_id': clientRequestId,
      'status': SyncStatus.pending.value,
      'retry_count': 0,
      'last_error': null,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (existing.isEmpty) {
      await database.insert('sync_queue', values);
    } else {
      await database.update(
        'sync_queue',
        values,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<List<SyncQueueItem>> pendingItems() async {
    final database = await _db.database;
    final rows = await database.query(
      'sync_queue',
      where: 'status != ?',
      whereArgs: [SyncStatus.synced.value],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(SyncQueueItem.fromMap).toList();
  }

  Future<int> pendingCount() async {
    final database = await _db.database;
    return Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT COUNT(*) FROM sync_queue WHERE status != ?',
            [SyncStatus.synced.value],
          ),
        ) ??
        0;
  }

  Future<void> markSyncing(int id) async {
    final database = await _db.database;
    await database.update(
      'sync_queue',
      {'status': SyncStatus.syncing.value, 'last_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markError(int id, String error, int retryCount) async {
    final database = await _db.database;
    await database.update(
      'sync_queue',
      {
        'status': SyncStatus.error.value,
        'last_error': error,
        'retry_count': retryCount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markDone(int id) => _db.deleteQueueItem(id);
}
