import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = "http://10.0.2.2:8000";

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({
    super.key,
    this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late TextEditingController tokenController;
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String? message;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    tokenController = TextEditingController(text: widget.token ?? "");
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Pole „Nowe hasło” jest wymagane.';
    }

    if (value.length < 8) {
      return 'Hasło musi mieć co najmniej 8 znaków.';
    }

    if (value.length > 255) {
      return 'Hasło może mieć maksymalnie 255 znaków.';
    }

    final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]');

    if (!specialCharRegex.hasMatch(value)) {
      return 'Hasło musi zawierać co najmniej jeden znak specjalny.';
    }

    return null;
  }

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
      message = null;
      errorMessage = null;
    });

    final token = tokenController.text.trim();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (token.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Wklej token resetujący z wiadomości e-mail.';
      });
      return;
    }

    final passwordError = validatePassword(newPassword);
    if (passwordError != null) {
      setState(() {
        isLoading = false;
        errorMessage = passwordError;
      });
      return;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Powtórz nowe hasło.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        isLoading = false;
        errorMessage = 'Hasła nie są takie same.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/reset-password"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "token": token,
          "new_password": newPassword,
          "confirm_password": confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          message = data["message"] ?? "Hasło zostało zmienione.";
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        });
      } else {
        setState(() {
          errorMessage = data["detail"] ?? "Wystąpił błąd.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Nie udało się połączyć z serwerem.";
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F0E8),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color(0xFF263B63),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Text(
                    "Zmiana hasła",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263B63),
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: tokenController,
                    decoration: InputDecoration(
                      labelText: "Token z maila",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Nowe hasło",
                      helperText: "Minimum 8 znaków i co najmniej jeden znak specjalny.",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Powtórz nowe hasło",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (message != null)
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.green),
                    ),

                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263B63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "Zmień hasło",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}