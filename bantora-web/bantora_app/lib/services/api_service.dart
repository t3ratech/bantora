import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poll.dart';
import '../models/idea.dart';

class ApiService {
  final String baseUrl;

  String? _accessToken;
  String? _refreshToken;

  ApiService({required this.baseUrl});

  void setAccessToken(String token) {
    if (token.isEmpty) {
      throw StateError('Access token must not be empty');
    }
    _accessToken = token;
  }

  void setRefreshToken(String? token) {
    _refreshToken = token;
  }

  void clearAuth() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> _jsonHeaders({bool requireAuth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Missing access token for authenticated request');
      }
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _unwrapApiResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  bool _isSuccessfulEnvelope(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
      final successValue = decoded['success'];
      return successValue == true;
    }
    return false;
  }

  Future<Map<String, dynamic>> login({required String phoneNumber, required String password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({'phoneNumber': phoneNumber, 'password': password}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Login failed: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final payload = _unwrapApiResponse(decoded);
    if (payload is! Map<String, dynamic>) {
      throw StateError('Invalid login response payload');
    }
    return payload;
  }

  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String password,
    required String countryCode,
    String? fullName,
    String? email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'password': password,
        'countryCode': countryCode,
        if (fullName != null) 'fullName': fullName,
        if (email != null) 'email': email,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Register failed: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    final payload = _unwrapApiResponse(decoded);
    if (payload is! Map<String, dynamic>) {
      throw StateError('Invalid register response payload');
    }
    return payload;
  }

  Future<void> logout({required String refreshToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Logout failed: HTTP ${response.statusCode}');
    }
  }

  // Get all polls
  Future<List<Poll>> getPolls() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/polls'));
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final dynamic payload = _unwrapApiResponse(decoded);

        if (payload is List) {
          return payload
              .whereType<Map<String, dynamic>>()
              .map((json) => Poll.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching polls: $e');
      return [];
    }
  }

  // Get single poll
  Future<Poll?> getPoll(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/polls/$id'));
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final dynamic payload = _unwrapApiResponse(decoded);

        if (payload is Map<String, dynamic>) {
          return Poll.fromJson(payload);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching poll: $e');
      return null;
    }
  }

  // Create poll
  Future<Poll?> createPoll({
    required String title,
    required String description,
    required String scope,
    required List<String> options,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/polls'),
        headers: _jsonHeaders(requireAuth: true),
        body: jsonEncode({
          'title': title,
          'description': description,
          'scope': scope,
          'options': options,
        }),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final dynamic payload = _unwrapApiResponse(decoded);

        if (payload is Map<String, dynamic>) {
          return Poll.fromJson(payload);
        }
      }
      return null;
    } catch (e) {
      print('Error creating poll: $e');
      return null;
    }
  }

  // Get ideas
  Future<List<Idea>> getIdeas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/ideas'));
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final dynamic payload = _unwrapApiResponse(decoded);

        if (payload is List) {
          return payload
              .whereType<Map<String, dynamic>>()
              .map((json) => Idea.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching ideas: $e');
      return [];
    }
  }

  // Create idea
  Future<bool> createIdea({required String content}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ideas'),
        headers: _jsonHeaders(requireAuth: true),
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);
      return _isSuccessfulEnvelope(decoded);
    } catch (e) {
      print('Error creating idea: $e');
      return false;
    }
  }

  // Upvote idea
  Future<bool> upvoteIdea(String ideaId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ideas/$ideaId/upvote'),
        headers: _jsonHeaders(requireAuth: true),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);
      return _isSuccessfulEnvelope(decoded);
    } catch (e) {
      print('Error upvoting idea: $e');
      return false;
    }
  }

  // Vote on poll
  Future<bool> vote({
    required String pollId,
    required String optionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/votes'),
        headers: _jsonHeaders(requireAuth: true),
        body: jsonEncode({
          'pollId': pollId,
          'optionId': optionId,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);
      return _isSuccessfulEnvelope(decoded);
    } catch (e) {
      print('Error voting: $e');
      return false;
    }
  }
}
