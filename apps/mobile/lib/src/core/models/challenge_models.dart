part of '../../../main.dart';

enum ChallengeType { mystery, officeSafari, technicalInspector }

class ChallengeItem {
  ChallengeItem({required this.code, required this.label});
  final String code;
  final String label;
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

class SubmissionModel {
  SubmissionModel({
    required this.id,
    required this.challengeId,
    required this.status,
  });
  final int id;
  final int challengeId;
  final String status;

  factory SubmissionModel.fromJson(Map<String, dynamic> json) =>
      SubmissionModel(
        id: json['id'] as int,
        challengeId: json['challengeId'] as int,
        status: json['status'] as String,
      );
}
