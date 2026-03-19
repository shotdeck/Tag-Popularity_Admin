import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tag_popularity.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  String get _tagPopularityEndpoint => '$baseUrl/api/admin/tag-popularity';

  Future<List<TagPopularity>> getAll() async {
    final response = await http.get(
      Uri.parse(_tagPopularityEndpoint),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => TagPopularity.fromJson(json)).toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<TagPopularity> getById(int id) async {
    final response = await http.get(
      Uri.parse('$_tagPopularityEndpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return TagPopularity.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<TagPopularity> create(CreateTagPopularityRequest request) async {
    final response = await http.post(
      Uri.parse(_tagPopularityEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return TagPopularity.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<TagPopularity> update(int id, UpdateTagPopularityRequest request) async {
    final response = await http.put(
      Uri.parse('$_tagPopularityEndpoint/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return TagPopularity.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<void> delete(int id) async {
    final response = await http.delete(
      Uri.parse('$_tagPopularityEndpoint/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<bool> checkPassword(String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Search/check-tag-popularity-password?password=${Uri.encodeComponent(password)}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result is bool) {
        return result;
      }
      return result == true || result == 'true';
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  Future<List<TagSearchResult>> searchTags(String tag) async {
    final response = await http.get(
      Uri.parse('$_tagPopularityEndpoint/search?tag=${Uri.encodeComponent(tag)}'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList
          .map((item) => TagSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _parseErrorMessage(response.body),
      );
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final jsonBody = json.decode(body);
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody['message'] ?? jsonBody['Message'] ?? body;
      }
      return body;
    } catch (_) {
      return body;
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}
