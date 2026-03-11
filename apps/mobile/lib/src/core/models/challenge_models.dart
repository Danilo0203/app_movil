part of '../../../main.dart';

enum ChallengeType { mystery, officeSafari, technicalInspector }

class ChallengeItem {
  ChallengeItem({required this.code, required this.label});
  final String code;
  final String label;

  Map<String, dynamic> toJson() => {'code': code, 'label': label};
}

class ChallengeModel {
  ChallengeModel({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
  });

  final int id;
  final String title;
  final ChallengeType type;
  final List<ChallengeItem> items;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': switch (type) {
      ChallengeType.mystery => 'MYSTERY',
      ChallengeType.officeSafari => 'OFFICE_SAFARI',
      ChallengeType.technicalInspector => 'TECHNICAL_INSPECTOR',
    },
    'itemsJson': items.map((item) => item.toJson()).toList(),
  };

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['itemsJson'] as List<dynamic>? ?? const []);
    return ChallengeModel(
      id: json['id'] as int,
      title: json['title'] as String,
      type: _parseChallengeType(json['type'] as String? ?? ''),
      items: rawItems
          .map(
            (e) => ChallengeItem(
              code: (e as Map<String, dynamic>)['code'] as String,
              label: e['label'] as String,
            ),
          )
          .toList(),
    );
  }
}

ChallengeType _parseChallengeType(String value) {
  switch (value) {
    case 'MYSTERY':
      return ChallengeType.mystery;
    case 'OFFICE_SAFARI':
      return ChallengeType.officeSafari;
    case 'TECHNICAL_INSPECTOR':
      return ChallengeType.technicalInspector;
    default:
      return ChallengeType.mystery;
  }
}

class AuthSession {
  AuthSession({
    required this.accessToken,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  final String accessToken;
  final int userId;
  final String userName;
  final String userEmail;

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
  };

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    userId: json['userId'] as int,
    userName: json['userName'] as String,
    userEmail: json['userEmail'] as String,
  );
}

class UserProfileModel {
  UserProfileModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.avatarUrl,
    this.localAvatarPath,
    this.syncStatus = SyncStatus.synced,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final String? localAvatarPath;
  final SyncStatus syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String?,
        address: json['address'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        localAvatarPath: json['localAvatarPath'] as String?,
        syncStatus: parseSyncStatus(json['syncStatus'] as String?),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'avatarUrl': avatarUrl,
    'localAvatarPath': localAvatarPath,
    'syncStatus': syncStatus.value,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  UserProfileModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    Object? localAvatarPath = _sentinel,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      localAvatarPath: localAvatarPath == _sentinel
          ? this.localAvatarPath
          : localAvatarPath as String?,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubmissionModel {
  SubmissionModel({
    required this.id,
    required this.localId,
    required this.challengeId,
    required this.status,
    required this.evidences,
    this.remoteId,
    this.syncStatus = SyncStatus.synced,
    this.pendingComplete = false,
    this.lastError,
    this.createdAt,
    this.updatedAt,
  });
  final int id;
  final String localId;
  final int? remoteId;
  final int challengeId;
  final String status;
  final List<SubmissionEvidenceModel> evidences;
  final SyncStatus syncStatus;
  final bool pendingComplete;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) =>
      SubmissionModel(
        id: json['id'] as int,
        localId: 'remote-${json['id']}',
        remoteId: json['id'] as int,
        challengeId: json['challengeId'] as int,
        status: json['status'] as String,
        syncStatus: SyncStatus.synced,
        pendingComplete: false,
        lastError: null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'].toString())
            : (json['createdAt'] != null
                  ? DateTime.tryParse(json['createdAt'].toString())
                  : null),
        evidences: (json['evidences'] as List<dynamic>? ?? const [])
            .map(
              (e) =>
                  SubmissionEvidenceModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  factory SubmissionModel.fromLocal(
    LocalSubmissionRecord record,
    List<LocalEvidenceRecord> evidences,
  ) {
    return SubmissionModel(
      id: record.remoteId ?? -record.localId.hashCode.abs(),
      localId: record.localId,
      remoteId: record.remoteId,
      challengeId: record.challengeId,
      status: record.status,
      syncStatus: record.syncStatus,
      pendingComplete: record.pendingComplete,
      lastError: record.lastError,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      evidences: evidences
          .map((evidence) => SubmissionEvidenceModel.fromLocal(evidence))
          .toList(),
    );
  }
}

class SubmissionEvidenceModel {
  SubmissionEvidenceModel({
    required this.itemCode,
    required this.photoPath,
    this.localId = '',
    this.localFilePath,
    this.syncStatus = SyncStatus.synced,
    this.lastError,
  });

  final String itemCode;
  final String photoPath;
  final String localId;
  final String? localFilePath;
  final SyncStatus syncStatus;
  final String? lastError;

  factory SubmissionEvidenceModel.fromJson(Map<String, dynamic> json) =>
      SubmissionEvidenceModel(
        itemCode: json['itemCode'] as String,
        photoPath: json['photoPath'] as String,
      );

  factory SubmissionEvidenceModel.fromLocal(LocalEvidenceRecord record) =>
      SubmissionEvidenceModel(
        itemCode: record.itemCode,
        photoPath: record.remotePhotoPath ?? '',
        localId: record.localId,
        localFilePath: record.localFilePath.isEmpty
            ? null
            : record.localFilePath,
        syncStatus: record.syncStatus,
        lastError: record.lastError,
      );
}

const _sentinel = Object();
