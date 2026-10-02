import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import '../services/friend_service.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navy = Color(0xFF263B63);
  static const Color lightBlue = Color(0xFFDDF4F6);

  final AuthService _authService = AuthService();
  final FriendService _friendService = FriendService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _username;
  String? _firstName;
  String? _lastName;
  File? _profileImage;
  String? _profileImageUrl;

  List<Map<String, dynamic>> _friends = [];

  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isLoadingFriends = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getLoggedUser();
      final friends = await _friendService.getFriends();

      if (!mounted) return;

      setState(() {
        _username = user?['username'];
        _firstName = user?['first_name'] ?? user?['name'] ?? user?['firstName'];
        _lastName = user?['last_name'] ?? user?['surname'] ?? user?['lastName'];
        _profileImageUrl = user?['profile_image_url'];
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadFriends() async {
    if (_isLoadingFriends) return;

    setState(() => _isLoadingFriends = true);

    try {
      final friends = await _friendService.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingFriends = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickProfileImage() async {
    if (_isUploadingImage) return;

    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (selectedImage == null || !mounted) return;

    setState(() => _isUploadingImage = true);

    try {
      final imageUrl = await _authService.uploadProfileImage(selectedImage.path);
      if (!mounted) return;

      setState(() {
        _profileImage = File(selectedImage.path);
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      _showMessage('Zdjęcie profilowe zostało zapisane.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String? get _fullProfileImageUrl => _fullImageUrl(_profileImageUrl);

  String? _fullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return null;
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '${AuthService.baseUrl}$imageUrl';
  }

  String get _displayName {
    final parts = <String>[];
    if (_firstName?.trim().isNotEmpty == true) parts.add(_firstName!.trim());
    if (_lastName?.trim().isNotEmpty == true) parts.add(_lastName!.trim());
    return parts.isNotEmpty ? parts.join(' ') : (_username ?? 'Użytkownik');
  }

  String _friendDisplayName(Map<String, dynamic> friend) {
    final firstName = (friend['first_name'] ?? '').toString().trim();
    final lastName = (friend['last_name'] ?? '').toString().trim();
    final parts = <String>[];
    if (firstName.isNotEmpty) parts.add(firstName);
    if (lastName.isNotEmpty) parts.add(lastName);
    return parts.isEmpty ? 'Użytkownik' : parts.join(' ');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _showAddFriendSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        String email = '';
        String code = '';
        String? errorMessage;
        bool isSending = false;
        bool isAccepting = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> sendInvitation() async {
              final normalizedEmail = email.trim();

              if (normalizedEmail.isEmpty) {
                setSheetState(() {
                  errorMessage = 'Wpisz adres e-mail użytkownika.';
                });
                return;
              }

              setSheetState(() {
                isSending = true;
                errorMessage = null;
              });

              try {
                final message =
                await _friendService.sendInvitation(normalizedEmail);

                if (!sheetContext.mounted) return;

                FocusScope.of(sheetContext).unfocus();

                Navigator.of(sheetContext).pop({
                  'type': 'sent',
                  'message': message,
                });
              } catch (e) {
                if (!sheetContext.mounted) return;

                setSheetState(() {
                  isSending = false;
                  errorMessage = e
                      .toString()
                      .replaceFirst('Exception: ', '');
                });
              }
            }

            Future<void> acceptInvitation() async {
              final normalizedCode = code.trim();

              if (normalizedCode.isEmpty) {
                setSheetState(() {
                  errorMessage = 'Wpisz kod zaproszenia.';
                });
                return;
              }

              setSheetState(() {
                isAccepting = true;
                errorMessage = null;
              });

              try {
                final message = await _friendService
                    .acceptInvitation(normalizedCode);

                if (!sheetContext.mounted) return;

                FocusScope.of(sheetContext).unfocus();

                Navigator.of(sheetContext).pop({
                  'type': 'accepted',
                  'message': message,
                });
              } catch (e) {
                if (!sheetContext.mounted) return;

                setSheetState(() {
                  isAccepting = false;
                  errorMessage = e
                      .toString()
                      .replaceFirst('Exception: ', '');
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Dodaj znajomego',
                          style: TextStyle(
                            color: navy,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _sheetLabel('Adres e-mail użytkownika'),
                        const SizedBox(height: 6),
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            email = value;
                          },
                          decoration: _sheetInputDecoration(
                            'np. znajomy@gmail.com',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isSending || isAccepting
                                ? null
                                : sendInvitation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: isSending
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Wyślij zaproszenie',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'lub',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Mam kod zaproszenia',
                          style: TextStyle(
                            color: navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) {
                            code = value;
                          },
                          decoration: _sheetInputDecoration('RT-XXXXXX'),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: isSending || isAccepting
                                ? null
                                : acceptInvitation,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: navy,
                              side: const BorderSide(
                                color: navy,
                                width: 1.4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: isAccepting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: navy,
                              ),
                            )
                                : const Text(
                              'Akceptuj kod',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    // Dajemy bottom sheetowi i klawiaturze czas na pełne zamknięcie.
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) return;

    if (result['type'] == 'accepted') {
      await _loadFriends();
    }

    if (!mounted) return;

    final message = result['message'];

    if (message is String && message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  Widget _sheetLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: navy.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _sheetInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Future<void> _showFriendDetails(Map<String, dynamic> friend) async {
    final friendId = friend['id'];
    if (friendId is! int) return;

    Map<String, dynamic> details = friend;
    try {
      details = await _friendService.getFriendDetails(friendId);
    } catch (_) {}

    if (!mounted) return;

    final imageUrl = _fullImageUrl(details['profile_image_url']?.toString());
    final displayName = _friendDisplayName(details);
    final username = (details['username'] ?? '').toString();
    final email = (details['email'] ?? '').toString();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: imageUrl != null
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _friendFallback(54),
                      )
                          : _friendFallback(54),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    username.isEmpty ? '' : '@$username',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined, color: Colors.grey.shade600, size: 18),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            email,
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Usunąć znajomego?'),
                            content: Text(
                              'Czy na pewno chcesz usunąć ${username.isEmpty ? displayName : '@$username'} ze znajomych?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: const Text('Anuluj'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                child: const Text('Usuń'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed != true) return;

                        try {
                          final message = await _friendService.deleteFriend(friendId);
                          if (!mounted) return;
                          Navigator.pop(sheetContext);
                          await _loadFriends();
                          _showMessage(message);
                        } catch (e) {
                          _showMessage(e.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                      icon: const Icon(Icons.person_remove_outlined),
                      label: const Text('Usuń ze znajomych'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlue,
      bottomNavigationBar: Container(
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: IconButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  icon: const Icon(Icons.home, color: Colors.white, size: 34),
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: navy))
            : Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F4EE), Color(0xFFDDF4F6)],
            ),
          ),
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildHeaderImageAndAvatar(),
                      const SizedBox(height: 8),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _username ?? '',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                      const SizedBox(height: 22),
                      _buildFriendsCard(),
                      const SizedBox(height: 12),
                      _profileButton(
                        icon: Icons.folder_copy_outlined,
                        text: 'Dokumenty osobiste',
                        onTap: () {},
                      ),
                      _profileButton(
                        icon: Icons.settings,
                        text: 'Ustawienia',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _profileButton(
                        icon: Icons.help_outline,
                        text: 'Pomoc',
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 145,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            'Wyloguj',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.pets, color: navy, size: 38),
          SizedBox(width: 8),
          Column(
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
        ],
      ),
    );
  }

  Widget _buildHeaderImageAndAvatar() {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SizedBox(
            width: double.infinity,
            height: 130,
            child: Image.asset(
              'assets/images/profile_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 82,
            child: GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                    child: ClipOval(child: _buildProfileImage()),
                  ),
                  Positioned(
                    right: -2,
                    bottom: 2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: navy,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _isUploadingImage
                          ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_profileImage != null) {
      return Image.file(_profileImage!, width: 112, height: 112, fit: BoxFit.cover);
    }

    if (_fullProfileImageUrl != null) {
      return Image.network(
        _fullProfileImageUrl!,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultAvatar(),
      );
    }

    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(Icons.person, color: Colors.grey.shade500, size: 78),
    );
  }

  Widget _friendFallback(double iconSize) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.person, color: Colors.grey.shade500, size: iconSize),
    );
  }

  Widget _buildFriendAvatar(Map<String, dynamic> friend) {
    final imageUrl = _fullImageUrl(friend['profile_image_url']?.toString());

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _friendFallback(28),
        )
            : _friendFallback(28),
      ),
    );
  }

  Widget _buildFriendsCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Moi znajomi:',
                  style: TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: _showAddFriendSheet,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade600, width: 1.4),
                  ),
                  child: Icon(Icons.add, color: Colors.grey.shade600, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingFriends)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: navy),
              ),
            )
          else if (_friends.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Nie masz jeszcze znajomych.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            )
          else
            ..._friends.map((friend) {
              final username = (friend['username'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFriendDetails(friend),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                      child: Row(
                        children: [
                          _buildFriendAvatar(friend),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username.isEmpty ? 'Użytkownik' : '@$username',
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _friendDisplayName(friend),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _profileButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey.shade600, size: 28),
                const SizedBox(width: 15),
                Text(text, style: const TextStyle(color: navy, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
