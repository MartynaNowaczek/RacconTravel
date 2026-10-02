import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';


class FriendService {
  final AuthService _authService = AuthService();

  Future<String> sendInvitation(
      String email,
      ) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception(
        'Brak tokenu użytkownika.',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${AuthService.baseUrl}/friends/invitations',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
      }),
    );

    final data = _decodeResponse(
      response.body,
    );

    if (response.statusCode == 200) {
      return data['message'] ??
          'Zaproszenie zostało wysłane.';
    }

    throw Exception(
      _getErrorMessage(data),
    );
  }


  Future<String> acceptInvitation(
      String code,
      ) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception(
        'Brak tokenu użytkownika.',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${AuthService.baseUrl}/friends/invitations/accept',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'code': code.trim().toUpperCase(),
      }),
    );

    final data = _decodeResponse(
      response.body,
    );

    if (response.statusCode == 200) {
      return data['message'] ??
          'Zaproszenie zostało zaakceptowane.';
    }

    throw Exception(
      _getErrorMessage(data),
    );
  }


  Future<List<Map<String, dynamic>>> getFriends() async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception(
        'Brak tokenu użytkownika.',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${AuthService.baseUrl}/friends',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data =
      jsonDecode(response.body);

      return data
          .map(
            (friend) =>
        Map<String, dynamic>.from(
          friend,
        ),
      )
          .toList();
    }

    final data = _decodeResponse(
      response.body,
    );

    throw Exception(
      _getErrorMessage(data),
    );
  }


  Future<Map<String, dynamic>> getFriendDetails(
      int userId,
      ) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception(
        'Brak tokenu użytkownika.',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${AuthService.baseUrl}/friends/$userId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(
      response.body,
    );

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(
      _getErrorMessage(data),
    );
  }


  Future<String> deleteFriend(
      int userId,
      ) async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception(
        'Brak tokenu użytkownika.',
      );
    }

    final response = await http.delete(
      Uri.parse(
        '${AuthService.baseUrl}/friends/$userId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decodeResponse(
      response.body,
    );

    if (response.statusCode == 200) {
      return data['message'] ??
          'Użytkownik został usunięty ze znajomych.';
    }

    throw Exception(
      _getErrorMessage(data),
    );
  }


  Map<String, dynamic> _decodeResponse(
      String responseBody,
      ) {
    if (responseBody.isEmpty) {
      return {};
    }

    try {
      final decoded =
      jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {};
    } catch (_) {
      return {};
    }
  }


  String _getErrorMessage(
      Map<String, dynamic> data,
      ) {
    final detail = data['detail'];

    if (detail is String) {
      return detail;
    }

    return 'Wystąpił błąd podczas komunikacji z serwerem.';
  }
}