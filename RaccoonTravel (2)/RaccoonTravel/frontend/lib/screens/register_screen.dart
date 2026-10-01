import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'trips_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPasswordController = TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  final nameRegex = RegExp(
    r'^[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+([ -][A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+)*$',
  );

  final emailRegex = RegExp(
    r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$',
  );

  String? validateFirstName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Pole „Imię” jest wymagane.';
    }

    if (text.length < 2) {
      return 'Pole „Imię” musi mieć co najmniej 2 znaki.';
    }

    if (!nameRegex.hasMatch(text)) {
      return 'Imię może zawierać tylko litery, pojedyncze spacje lub myślnik.';
    }

    return null;
  }

  String? validateLastName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Pole „Nazwisko” jest wymagane.';
    }

    if (text.length < 2) {
      return 'Pole „Nazwisko” musi mieć co najmniej 2 znaki.';
    }

    if (!nameRegex.hasMatch(text)) {
      return 'Nazwisko może zawierać tylko litery, pojedyncze spacje lub myślnik.';
    }

    return null;
  }

  String? validateUsername(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Pole „Nazwa użytkownika” jest wymagane.';
    }

    if (text.length < 3) {
      return 'Nazwa użytkownika musi mieć co najmniej 3 znaki.';
    }

    if (text.length > 100) {
      return 'Nazwa użytkownika może mieć maksymalnie 100 znaków.';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Pole „E-mail” jest wymagane.';
    }

    if (!emailRegex.hasMatch(text)) {
      return 'Podaj poprawny adres e-mail.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Pole „Hasło” jest wymagane.';
    }

    if (text.length < 8) {
      return 'Hasło musi mieć co najmniej 8 znaków.';
    }

    if (text.length > 255) {
      return 'Hasło może mieć maksymalnie 255 znaków.';
    }

    final specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]');

    if (!specialCharRegex.hasMatch(text)) {
      return 'Hasło musi zawierać co najmniej jeden znak specjalny.';
    }

    return null;
  }

  String? validateRepeatPassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) {
      return 'Pole „Powtórz hasło” jest wymagane.';
    }

    if (text != passwordController.text) {
      return 'Hasła muszą być takie same.';
    }

    return null;
  }

  Future<void> register() async {
    setState(() {
      errorMessage = null;
    });

    final isFormValid = formKey.currentState!.validate();

    if (!isFormValid) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    final registerError = await authService.register(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (registerError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konto zostało utworzone. Możesz się zalogować.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      setState(() {
        errorMessage = registerError;
      });
    }
  }

  Future<void> registerWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final success = await authService.loginWithGoogle();

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const TripsScreen(),
        ),
      );
    } else {
      setState(() {
        errorMessage = 'Nie udało się zarejestrować przez Google.';
      });
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    repeatPasswordController.dispose();
    super.dispose();
  }

  Widget buildInput({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          errorMaxLines: 2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F0E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const Text(
                    '🦝',
                    style: TextStyle(fontSize: 42),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Rejestracja',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263B63),
                    ),
                  ),

                  const SizedBox(height: 28),

                  buildInput(
                    label: 'Imię',
                    controller: firstNameController,
                    validator: validateFirstName,
                  ),

                  buildInput(
                    label: 'Nazwisko',
                    controller: lastNameController,
                    validator: validateLastName,
                  ),

                  buildInput(
                    label: 'Nazwa użytkownika',
                    controller: usernameController,
                    validator: validateUsername,
                  ),

                  buildInput(
                    label: 'E-mail',
                    controller: emailController,
                    validator: validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  buildInput(
                    label: 'Hasło',
                    controller: passwordController,
                    validator: validatePassword,
                    obscureText: true,
                  ),

                  buildInput(
                    label: 'Powtórz hasło',
                    controller: repeatPasswordController,
                    validator: validateRepeatPassword,
                    obscureText: true,
                  ),

                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: 220,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF263B63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        'Zarejestruj',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: 220,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : registerWithGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text(
                        'Zarejestruj przez Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF263B63),
                        side: const BorderSide(
                          color: Color(0xFF263B63),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Zaloguj się',
                      style: TextStyle(
                        color: Color(0xFF263B63),
                        fontWeight: FontWeight.w600,
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