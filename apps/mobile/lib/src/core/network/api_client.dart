part of '../../../main.dart';

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  static const _requestTimeout = Duration(seconds: 20);
  final String baseUrl;
  final String? token;

  Uri _uri(String path) =>
      Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  Map<String, String> _headers({bool auth = false}) => {
    'Content-Type': 'application/json',
    if (auth && token != null) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          _uri('/auth/register'),
          headers: _headers(),
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(_requestTimeout);
    return _decodeObject(res);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          _uri('/auth/login'),
          headers: _headers(),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_requestTimeout);
    return _decodeObject(res);
  }

  Future<List<ChallengeModel>> listChallenges() async {
    final res = await http.get(_uri('/challenges')).timeout(_requestTimeout);
    final list = _decodeList(res);
    return list.map((e) => ChallengeModel.fromJson(e)).toList();
  }

  Future<void> seedChallenges() async {
    final res = await http
        .post(_uri('/challenges/seed-defaults'))
        .timeout(_requestTimeout);
    if (res.statusCode >= 400) throw Exception(_readError(res));
  }

  Future<SubmissionModel> createSubmission(int challengeId) async {
    final res = await http
        .post(
          _uri('/submissions'),
          headers: _headers(auth: true),
          body: jsonEncode({'challengeId': challengeId}),
        )
        .timeout(_requestTimeout);
    return SubmissionModel.fromJson(_decodeObject(res));
  }

  Future<Map<String, dynamic>> uploadEvidence({
    required int submissionId,
    required String itemCode,
    required File file,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      _uri('/submissions/$submissionId/photos'),
    );
    if (token != null) {
      req.headers['Authorization'] = 'Bearer $token';
    }
    req.fields['itemCode'] = itemCode;
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send().timeout(_requestTimeout);
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 400) {
      throw Exception(_parseErrorBody(body));
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> completeSubmission(int submissionId) async {
    final res = await http
        .post(
          _uri('/submissions/$submissionId/complete'),
          headers: _headers(auth: true),
        )
        .timeout(_requestTimeout);
    return _decodeObject(res);
  }

  Future<List<Map<String, dynamic>>> ranking() async {
    final res = await http
        .get(_uri('/ranking/global'))
        .timeout(_requestTimeout);
    return _decodeList(res);
  }

  Map<String, dynamic> _decodeObject(http.Response res) {
    if (res.statusCode >= 400) throw Exception(_readError(res));
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _decodeList(http.Response res) {
    if (res.statusCode >= 400) throw Exception(_readError(res));
    final raw = jsonDecode(res.body) as List<dynamic>;
    return raw.cast<Map<String, dynamic>>();
  }

  String _readError(http.Response res) {
    try {
      final json = jsonDecode(res.body);
      if (json is Map && json['message'] != null) {
        final message = json['message'];
        if (message is List) return message.join(', ');
        return message.toString();
      }
    } catch (_) {}
    return 'HTTP ${res.statusCode}: ${res.body}';
  }

  String _parseErrorBody(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] != null) {
        final message = json['message'];
        if (message is List) return message.join(', ');
        return message.toString();
      }
    } catch (_) {}
    return body;
  }
}
