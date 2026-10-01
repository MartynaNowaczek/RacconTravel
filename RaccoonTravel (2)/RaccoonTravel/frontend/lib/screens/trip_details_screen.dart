import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  static const Color navy = Color(0xFF263B63);
  static const Color background = Color(0xFFF6F0E8);
  static const Color lightBlue = Color(0xFFEAF9FB);

  final AuthService _authService = AuthService();
  String? _username;

  Trip get trip => widget.trip;

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
    });
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

  @override

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
                    size: 32,
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
        child: Container(
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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildTripPhoto(),
                      _buildTripInformation(),
                      const SizedBox(height: 22),
                      _menuButton(
                        icon: Icons.calendar_month,
                        text: 'Kalendarz',
                        onTap: () {},
                      ),
                      _menuButton(
                        icon: Icons.note_alt_outlined,
                        text: 'Notatki',
                        onTap: () {},
                      ),
                      _menuButton(
                        icon: Icons.checklist,
                        text: 'Listy',
                        onTap: () {},
                      ),
                      _menuButton(
                        icon: Icons.folder_copy_outlined,
                        text: 'Dokumenty',
                        onTap: () {},
                      ),
                      _menuButton(
                        icon: Icons.payments_outlined,
                        text: 'Budżet',
                        onTap: () {},
                      ),
                      const SizedBox(height: 28),
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

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
      child: Row(
        children: [
          const Icon(
            Icons.pets,
            color: navy,
            size: 34,
          ),
          const SizedBox(width: 8),
          const Column(
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
                  height: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _username ?? '',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                ],
              ),
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
    );
  }

  Widget _buildTripPhoto() {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: trip.photoUrl == null
          ? Container(
        color: Colors.blueGrey.shade100,
        child: const Icon(
          Icons.landscape,
          size: 70,
          color: Colors.white,
        ),
      )
          : Image.network(
        trip.photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.blueGrey.shade100,
            child: const Icon(
              Icons.landscape,
              size: 70,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTripInformation() {
    return Container(
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.92),
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.tripName,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cel: ${trip.destinationName}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Z: ${trip.originName}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
              // Tutaj później możesz dodać akcję po kliknięciu plusa.
            },
            borderRadius: BorderRadius.circular(30),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1.4,
                ),
              ),
              child: Icon(
                Icons.add,
                color: Colors.grey.shade500,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 34,
        vertical: 6,
      ),
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: navy,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Text(
                  text,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
