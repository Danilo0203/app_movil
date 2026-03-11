part of '../../../main.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();
  static const _dbName = 'app_creditos_offline.db';
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_challenges(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            payload_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_profile(
            user_id INTEGER PRIMARY KEY,
            payload_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cached_ranking(
            id INTEGER PRIMARY KEY CHECK (id = 1),
            payload_json TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE local_submissions(
            local_id TEXT PRIMARY KEY,
            user_id INTEGER NOT NULL,
            challenge_id INTEGER NOT NULL,
            remote_id INTEGER,
            status TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            pending_complete INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE local_evidences(
            local_id TEXT PRIMARY KEY,
            submission_local_id TEXT NOT NULL,
            item_code TEXT NOT NULL,
            local_file_path TEXT NOT NULL,
            remote_photo_path TEXT,
            sync_status TEXT NOT NULL,
            client_request_id TEXT NOT NULL,
            last_error TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            UNIQUE(submission_local_id, item_code)
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_queue(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_local_id TEXT NOT NULL,
            operation_type TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            file_path TEXT,
            client_request_id TEXT NOT NULL UNIQUE,
            status TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> cacheChallenges(List<ChallengeModel> challenges) async {
    final db = await database;
    await db.insert('cached_challenges', {
      'id': 1,
      'payload_json': jsonEncode(challenges.map((e) => e.toJson()).toList()),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CachedListResult<ChallengeModel>> readCachedChallenges() async {
    final db = await database;
    final rows = await db.query('cached_challenges', where: 'id = 1');
    if (rows.isEmpty) {
      return CachedListResult(items: const [], fromCache: true);
    }
    final row = rows.first;
    final payload = jsonDecode(row['payload_json']! as String) as List<dynamic>;
    return CachedListResult(
      items: payload
          .map((item) => ChallengeModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      fromCache: true,
      cachedAt: DateTime.tryParse(row['cached_at']! as String),
    );
  }

  Future<void> cacheProfile(int userId, UserProfileModel profile) async {
    final db = await database;
    await db.insert('cached_profile', {
      'user_id': userId,
      'payload_json': jsonEncode(profile.toJson()),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CachedValueResult<UserProfileModel>> readCachedProfile(
    int userId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'cached_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (rows.isEmpty) {
      return CachedValueResult(value: null, fromCache: true);
    }
    final row = rows.first;
    return CachedValueResult(
      value: UserProfileModel.fromJson(
        jsonDecode(row['payload_json']! as String) as Map<String, dynamic>,
      ),
      fromCache: true,
      cachedAt: DateTime.tryParse(row['cached_at']! as String),
    );
  }

  Future<void> cacheRanking(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.insert('cached_ranking', {
      'id': 1,
      'payload_json': jsonEncode(rows),
      'cached_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CachedListResult<Map<String, dynamic>>> readCachedRanking() async {
    final db = await database;
    final rows = await db.query('cached_ranking', where: 'id = 1');
    if (rows.isEmpty) {
      return CachedListResult(items: const [], fromCache: true);
    }
    final row = rows.first;
    final payload = jsonDecode(row['payload_json']! as String) as List<dynamic>;
    return CachedListResult(
      items: payload.cast<Map<String, dynamic>>(),
      fromCache: true,
      cachedAt: DateTime.tryParse(row['cached_at']! as String),
    );
  }

  Future<void> upsertSubmission(LocalSubmissionRecord record) async {
    final db = await database;
    await db.insert(
      'local_submissions',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalSubmissionRecord?> findSubmissionByLocalId(String localId) async {
    final db = await database;
    final rows = await db.query(
      'local_submissions',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalSubmissionRecord.fromMap(rows.first);
  }

  Future<LocalSubmissionRecord?> findSubmissionByRemoteId(int remoteId) async {
    final db = await database;
    final rows = await db.query(
      'local_submissions',
      where: 'remote_id = ?',
      whereArgs: [remoteId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalSubmissionRecord.fromMap(rows.first);
  }

  Future<LocalSubmissionRecord?> findLatestSubmissionForChallenge({
    required int userId,
    required int challengeId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'local_submissions',
      where: 'user_id = ? AND challenge_id = ?',
      whereArgs: [userId, challengeId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalSubmissionRecord.fromMap(rows.first);
  }

  Future<List<LocalSubmissionRecord>> listSubmissionsForUser(int userId) async {
    final db = await database;
    final rows = await db.query(
      'local_submissions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(LocalSubmissionRecord.fromMap).toList();
  }

  Future<void> upsertEvidence(LocalEvidenceRecord record) async {
    final db = await database;
    await db.insert(
      'local_evidences',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LocalEvidenceRecord?> findEvidence({
    required String submissionLocalId,
    required String itemCode,
  }) async {
    final db = await database;
    final rows = await db.query(
      'local_evidences',
      where: 'submission_local_id = ? AND item_code = ?',
      whereArgs: [submissionLocalId, itemCode],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalEvidenceRecord.fromMap(rows.first);
  }

  Future<List<LocalEvidenceRecord>> listEvidencesForSubmission(
    String submissionLocalId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'local_evidences',
      where: 'submission_local_id = ?',
      whereArgs: [submissionLocalId],
      orderBy: 'created_at ASC',
    );
    return rows.map(LocalEvidenceRecord.fromMap).toList();
  }

  Future<void> deleteQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}
