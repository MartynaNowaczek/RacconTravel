import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color navy = Color(0xFF263B63);
  static const Color background = Color(0xFFF7F4EE);
  static const Color lightBlue = Color(0xFFDDF4F6);

  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
  TextEditingController();

  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  DateTime? _birthDate;
  String? _gender;

  String? _username;

  int? _userId;
  int _profileImageVersion =
      DateTime.now().millisecondsSinceEpoch;

  bool _isLoadingHeader = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getLoggedUser();

      if (!mounted) return;

      setState(() {
        _username = user?['username'];
        _userId = user?['id'];

        _profileImageVersion =
            DateTime.now().millisecondsSinceEpoch;

        _usernameController.text = _username ?? '';
        _isLoadingHeader = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingHeader = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  String? get _fullProfileImageUrl {
    if (_userId == null) return null;

    return '${AuthService.baseUrl}/users/$_userId/profile-image?v=$_profileImageVersion';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Wybierz';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day.$month.${date.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selected == null || !mounted) return;

    setState(() {
      _birthDate = selected;
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlue,
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                background,
                lightBlue,
              ],
            ),
          ),
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    children: [
                      _buildTitle(),
                      const SizedBox(height: 16),
                      _buildProfileSettingsCard(),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Powiadomienia',
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildSwitchTile(
                        title: 'Tryb ciemny',
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });

                          _showInfo(
                            'Tryb ciemny zostanie podłączony do całej aplikacji w kolejnym etapie.',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        children: [
          const Icon(
            Icons.pets,
            color: navy,
            size: 38,
          ),
          const SizedBox(width: 8),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Raccoon',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                'TRAVEL',
                style: TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isLoadingHeader)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: navy,
                strokeWidth: 2,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _username ?? '',
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: _fullProfileImageUrl != null
                        ? Image.network(
                      _fullProfileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _smallAvatarFallback();
                      },
                    )
                        : _smallAvatarFallback(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout,
                    color: navy,
                  ),
                  tooltip: 'Wyloguj',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _smallAvatarFallback() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: Colors.grey.shade500,
        size: 18,
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: navy.withValues(alpha: 0.28),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.settings,
                color: Colors.grey,
                size: 28,
              ),
              SizedBox(width: 7),
              Text(
                'Ustawienia',
                style: TextStyle(
                  color: navy,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Divider(
            color: navy.withValues(alpha: 0.28),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edytuj profil',
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          // NAZWA UŻYTKOWNIKA
          _label('Nazwa użytkownika'),

          const SizedBox(height: 5),

          TextField(
            controller: _usernameController,
            decoration: _inputDecoration(
              'Wpisz nazwę użytkownika',
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _smallButton(
                  text: 'Zapisz',
                  onPressed: () {
                    _showInfo(
                      'Zmiany profilu zostaną zapisane po podłączeniu endpointu edycji profilu.',
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _smallButton(
                  text: 'Anuluj',
                  onPressed: () {
                    _usernameController.text =
                        _username ?? '';
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(
            color: navy.withValues(alpha: 0.45),
          ),

          const SizedBox(height: 10),

          // ZMIANA HASŁA
          const Text(
            'Zmiana hasła',
            style: TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          _label('Obecne hasło'),

          const SizedBox(height: 5),

          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            decoration: _inputDecoration(''),
          ),

          const SizedBox(height: 10),

          _label('Nowe hasło'),

          const SizedBox(height: 5),

          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: _inputDecoration(''),
          ),

          const SizedBox(height: 10),

          _label('Powtórz nowe hasło'),

          const SizedBox(height: 5),

          TextField(
            controller: _repeatPasswordController,
            obscureText: true,
            decoration: _inputDecoration(''),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _smallButton(
                  text: 'Zapisz',
                  onPressed: () {
                    _showInfo(
                      'Zmiana hasła zostanie podłączona do backendu.',
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _smallButton(
                  text: 'Anuluj',
                  onPressed: () {
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _repeatPasswordController.clear();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(
            color: navy.withValues(alpha: 0.45),
          ),

          const SizedBox(height: 10),

          // DATA URODZENIA + PŁEĆ
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _label('Data urodzenia'),

                    const SizedBox(height: 5),

                    InkWell(
                      onTap: _pickBirthDate,
                      child: Container(
                        height: 44,
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _formatDate(_birthDate),
                                style: TextStyle(
                                  color: _birthDate == null
                                      ? Colors.grey.shade600
                                      : navy,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.calendar_month,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    _label('Płeć'),

                    const SizedBox(height: 5),

                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration:
                      _inputDecoration('Wybierz'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Kobieta',
                          child: Text('Kobieta'),
                        ),
                        DropdownMenuItem(
                          value: 'Mężczyzna',
                          child: Text('Mężczyzna'),
                        ),
                        DropdownMenuItem(
                          value: 'Nie podaję',
                          child: Text('Nie podaję'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _smallButton(
                  text: 'Zapisz',
                  onPressed: () {
                    _showInfo(
                      'Zapis tych danych zostanie podłączony do backendu.',
                    );
                  },
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _smallButton(
                  text: 'Anuluj',
                  onPressed: () {
                    setState(() {
                      _birthDate = null;
                      _gender = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: navy,
                fontSize: 15,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: navy,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 58,
      color: navy,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: IconButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                        (route) => route.isFirst,
                  );
                },
                icon: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          const Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 34,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: navy.withValues(alpha: 0.85),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
    );
  }
}