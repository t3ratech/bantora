import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/poll.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  // Get all polls
  Future<List<Poll>> getPolls() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/polls'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
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
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Poll.fromJson(data['data']);
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'scope': scope,
          'options': options,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Poll.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error creating poll: $e');
      return null;
    }
  }

  // Vote on poll
  Future<bool> vote({
    required String pollId,
    required String optionId,
    bool anonymous = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/votes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pollId': pollId,
          'optionId': optionId,
          'anonymous': anonymous,
        }),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error voting: $e');
      return false;
    }
  }
}
