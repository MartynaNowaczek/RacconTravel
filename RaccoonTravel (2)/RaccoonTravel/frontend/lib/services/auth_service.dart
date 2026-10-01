import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Dla emulatora Androida używamy 10.0.2.2 zamiast 127.0.0.1
  static const String baseUrl = 'http://10.0.2.2:8000';

  Future<bool> login(
      String email,
      String password,
      ) async {
    final url = Uri.parse(
      '$baseUrl/users/login',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type':
        'application/x-www-form-urlencoded',
      },
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(
        response.body,
      );

      final token =
      data['access_token'];

      final prefs =
      await SharedPreferences
          .getInstance();

      await prefs.setString(
        'token',
        token,
      );

      return true;
    }

    return false;
  }

  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn =
          GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId:
        '988379505257-6kfup1l6epfalkc8gjpv6ndguaqt5lp9.apps.googleusercontent.com',
      );

      final GoogleSignInAccount googleUser =
      await googleSignIn.authenticate(
        scopeHint: [
          'email',
          'profile',
        ],
      );

      final GoogleSignInAuthentication
      googleAuth =
          googleUser.authentication;

      final idToken =
          googleAuth.idToken;

      if (idToken == null) {
        print(
          'Google login error: idToken is null',
        );
        return false;
      }

      final response =
      await http.post(
        Uri.parse(
          '$baseUrl/users/google-login',
        ),
        headers: {
          'Content-Type':
          'application/json',
        },
        body: jsonEncode({
          'id_token': idToken,
        }),
      );

      if (response.statusCode ==
          200) {
        final data =
        jsonDecode(
          response.body,
        );

        final token =
        data['access_token'];

        final prefs =
        await SharedPreferences
            .getInstance();

        await prefs.setString(
          'token',
          token,
        );

        return true;
      }

      print(
        'Google login backend status: ${response.statusCode}',
      );

      print(
        'Google login backend body: ${response.body}',
      );

      return false;
    } catch (e) {
      print(
        'Google login error: $e',
      );

      return false;
    }
  }

  Future<String?> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse(
      '$baseUrl/users/register',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type':
        'application/json',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode ==
        201) {
      return null;
    }

    try {
      final data =
      jsonDecode(
        response.body,
      );

      if (data['detail']
      is String) {
        return data['detail'];
      }
    } catch (_) {
      return 'Nie udało się utworzyć konta.';
    }

    return 'Nie udało się utworzyć konta. Sprawdź dane.';
  }

  Future<String?> getToken() async {
    final prefs =
    await SharedPreferences
        .getInstance();

    return prefs.getString(
      'token',
    );
  }

  Future<void> logout() async {
    final prefs =
    await SharedPreferences
        .getInstance();

    await prefs.remove(
      'token',
    );
  }

  Future<Map<String, dynamic>?>
  getLoggedUser() async {
    final token =
    await getToken();

    if (token == null) {
      return null;
    }

    final response =
    await http.get(
      Uri.parse(
        '$baseUrl/users/me',
      ),
      headers: {
        'Authorization':
        'Bearer $token',
      },
    );

    if (response.statusCode ==
        200) {
      return jsonDecode(
        response.body,
      );
    }

    return null;
  }

  Future<String?> uploadProfileImage(
      String imagePath,
      ) async {
    final token =
    await getToken();

    if (token == null) {
      throw Exception(
        'Brak tokenu użytkownika.',
      );
    }

    final request =
    http.MultipartRequest(
      'POST',
      Uri.parse(
        '$baseUrl/users/me/profile-image',
      ),
    );

    request.headers[
    'Authorization'] =
    'Bearer $token';

    request.files.add(
      await http.MultipartFile
          .fromPath(
        'file',
        imagePath,
      ),
    );

    final streamedResponse =
    await request.send();

    final responseBody =
    await streamedResponse.stream
        .bytesToString();

    if (streamedResponse
        .statusCode ==
        200) {
      final data =
      jsonDecode(
        responseBody,
      );

      return data[
      'profile_image_url']
      as String?;
    }

    String message =
        'Nie udało się zapisać zdjęcia profilowego.';

    try {
      final data =
      jsonDecode(
        responseBody,
      );

      if (data['detail']
      is String) {
        message =
        data['detail'];
      }
    } catch (_) {}

    throw Exception(
      message,
    );
  }
}