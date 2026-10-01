import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navy = Color(0xFF263B63);
  static const Color lightBlue = Color(0xFFDDF4F6);

  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _username;
  String? _firstName;
  String? _lastName;

  File? _profileImage;
  String? _profileImageUrl;

  bool _isLoading = true;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getLoggedUser();

    if (!mounted) return;

    setState(() {
      _username = user?['username'];

      _firstName =
          user?['first_name'] ??
              user?['name'] ??
              user?['firstName'];

      _lastName =
          user?['last_name'] ??
              user?['surname'] ??
              user?['lastName'];

      _profileImageUrl =
      user?['profile_image_url'];

      _isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    if (_isUploadingImage) {
      return;
    }

    final XFile? selectedImage =
    await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (selectedImage == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final imageUrl =
      await _authService.uploadProfileImage(
        selectedImage.path,
      );

      if (!mounted) return;

      setState(() {
        _profileImage =
            File(selectedImage.path);

        _profileImageUrl =
            imageUrl;

        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Zdjęcie profilowe zostało zapisane.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  String? get _fullProfileImageUrl {
    if (_profileImageUrl == null ||
        _profileImageUrl!.trim().isEmpty) {
      return null;
    }

    if (_profileImageUrl!.startsWith(
      'http://',
    ) ||
        _profileImageUrl!.startsWith(
          'https://',
        )) {
      return _profileImageUrl;
    }

    return '${AuthService.baseUrl}$_profileImageUrl';
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const LoginScreen(),
      ),
          (route) => false,
    );
  }

  String get _displayName {
    final parts = <String>[];

    if (_firstName != null &&
        _firstName!.trim().isNotEmpty) {
      parts.add(
        _firstName!.trim(),
      );
    }

    if (_lastName != null &&
        _lastName!.trim().isNotEmpty) {
      parts.add(
        _lastName!.trim(),
      );
    }

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return _username ?? 'Użytkownik';
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
                alignment:
                Alignment.centerLeft,
                child: Padding(
                  padding:
                  const EdgeInsets.only(
                    left: 6,
                  ),
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
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
                          (route) =>
                      route.isFirst,
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
      ),

      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color: navy,
          ),
        )
            : Container(
          width: double.infinity,
          decoration:
          const BoxDecoration(
            gradient:
            LinearGradient(
              begin:
              Alignment.topCenter,
              end:
              Alignment.bottomCenter,
              colors: [
                Color(0xFFF7F4EE),
                Color(0xFFDDF4F6),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildTopBar(),

              Expanded(
                child:
                SingleChildScrollView(
                  padding:
                  EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildHeaderImageAndAvatar(),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        _displayName,
                        style:
                        const TextStyle(
                          color: navy,
                          fontSize: 18,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        _username ?? '',
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade700,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      _buildFriendsCard(),

                      const SizedBox(
                        height: 12,
                      ),

                      _profileButton(
                        icon: Icons
                            .folder_copy_outlined,
                        text:
                        'Dokumenty osobiste',
                        onTap: () {},
                      ),

                      _profileButton(
                        icon:
                        Icons.settings,
                        text:
                        'Ustawienia',
                        onTap: () {},
                      ),

                      _profileButton(
                        icon: Icons
                            .help_outline,
                        text: 'Pomoc',
                        onTap: () {},
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      SizedBox(
                        width: 145,
                        height: 44,
                        child:
                        ElevatedButton(
                          onPressed:
                          _logout,
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            navy,
                            foregroundColor:
                            Colors
                                .white,
                            elevation: 4,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                5,
                              ),
                            ),
                          ),
                          child:
                          const Text(
                            'Wyloguj',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight
                                  .bold,
                              fontSize:
                              15,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
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
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      child: const Row(
        children: [
          Icon(
            Icons.pets,
            color: navy,
            size: 38,
          ),

          SizedBox(
            width: 8,
          ),

          Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Raccoon',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                  height: 1,
                ),
              ),

              Text(
                'TRAVEL',
                style: TextStyle(
                  color: navy,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
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
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      color: Colors
                          .grey.shade300,
                      border:
                      Border.all(
                        color:
                        Colors.white,
                        width: 6,
                      ),
                    ),
                    child: ClipOval(
                      child:
                      _buildProfileImage(),
                    ),
                  ),

                  Positioned(
                    right: -2,
                    bottom: 2,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,
                        color: navy,
                        border:
                        Border.all(
                          color:
                          Colors.white,
                          width: 2,
                        ),
                      ),
                      child:
                      _isUploadingImage
                          ? const Padding(
                        padding:
                        EdgeInsets.all(
                          7,
                        ),
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons
                            .camera_alt,
                        color:
                        Colors.white,
                        size: 18,
                      ),
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
      return Image.file(
        _profileImage!,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
      );
    }

    if (_fullProfileImageUrl != null) {
      return Image.network(
        _fullProfileImageUrl!,
        width: 112,
        height: 112,
        fit: BoxFit.cover,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _defaultAvatar();
        },
      );
    }

    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: Colors.grey.shade500,
        size: 78,
      ),
    );
  }

  Widget _buildFriendsCard() {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      padding:
      const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.16,
            ),
            blurRadius: 5,
            offset:
            const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Moi znajomi:',
            style: TextStyle(
              color: navy,
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [
              InkWell(
                onTap: () {
                  // Dodawanie znajomych
                  // będzie obsłużone później.
                },
                borderRadius:
                BorderRadius.circular(
                  30,
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration:
                  BoxDecoration(
                    shape:
                    BoxShape.circle,
                    border:
                    Border.all(
                      color: Colors
                          .grey.shade600,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Colors
                        .grey.shade600,
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
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
      padding:
      const EdgeInsets.symmetric(
        horizontal: 28,
        vertical: 6,
      ),
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius:
        BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius:
          BorderRadius.circular(4),
          child: Container(
            height: 48,
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors
                      .grey.shade600,
                  size: 28,
                ),

                const SizedBox(
                  width: 15,
                ),

                Text(
                  text,
                  style:
                  const TextStyle(
                    color: navy,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}