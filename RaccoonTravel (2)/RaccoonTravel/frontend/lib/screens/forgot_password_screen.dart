import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'reset_password_screen.dart';

const String baseUrl = "http://10.0.2.2:8000";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;
  String? message;
  String? errorMessage;

  Future<void> sendResetEmail() async {
    setState(() {
      isLoading = true;
      message = null;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/users/forgot-password"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": emailController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          message = data["message"] ?? "Wysłano link do resetowania hasła.";
        });

        // Na razie możesz dać ręczne przejście do ekranu resetowania.
        // Docelowo ten ekran otworzy się po kliknięciu linku z maila.
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
      setState(() {
        isLoading = false;
      });
    }
  }

  void goToResetPasswordScreenForTesting() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResetPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Odzyskaj hasło"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Odzyskaj hasło",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  "Podaj adres e-mail przypisany do konta. Wyślemy link do resetowania hasła.",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Adres e-mail",
                    border: OutlineInputBorder(),
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

                ElevatedButton(
                  onPressed: isLoading ? null : sendResetEmail,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text("Potwierdź"),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: goToResetPasswordScreenForTesting,
                  child: const Text("Mam już token resetowania"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}