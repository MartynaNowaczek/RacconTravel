import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place_suggestion.dart';
import '../models/trip.dart';
import '../services/auth_service.dart';
import '../services/place_service.dart';
import '../services/trip_service.dart';
import 'login_screen.dart';
import 'trip_details_screen.dart';
import 'profile_screen.dart';
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final AuthService _authService = AuthService();
  final TripService _tripService = TripService();

  final TextEditingController _searchController = TextEditingController();

  List<Trip> _trips = [];
  String? _username;
  String? _profileImageUrl;

  bool _isLoading = true;
  bool _showFilters = false;

  String? _errorMessage;

  String _sort = 'newest';
  String? _selectedStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  Timer? _searchDebounce;

  static const Color navy = Color(0xFF263B63);
  static const Color background = Color(0xFFF6F0E8);
  static const Color lightBlue = Color(0xFFEAF9FB);

  List<Trip> get _filteredTrips {
    var result = [..._trips];

    final searchText = _searchController.text.trim().toLowerCase();

    if (searchText.isNotEmpty) {
      result = result.where((trip) {
        return trip.tripName.toLowerCase().contains(searchText) ||
            trip.destinationName.toLowerCase().contains(searchText);
      }).toList();
    }

    if (_selectedStatus != null) {
      result = result.where((trip) {
        return trip.status == _selectedStatus;
      }).toList();
    }

    if (_dateFrom != null) {
      result = result.where((trip) {
        return !trip.endDate.isBefore(_dateFrom!);
      }).toList();
    }

    if (_dateTo != null) {
      result = result.where((trip) {
        return !trip.startDate.isAfter(_dateTo!);
      }).toList();
    }

    return _sortTrips(result);
  }

  List<Trip> _sortTrips(List<Trip> trips) {
    final sortedTrips = [...trips];

    if (_sort == 'alpha') {
      sortedTrips.sort((a, b) {
        return a.destinationName.toLowerCase().compareTo(
          b.destinationName.toLowerCase(),
        );
      });
    }

    if (_sort == 'newest') {
      sortedTrips.sort((a, b) {
        return b.startDate.compareTo(a.startDate);
      });
    }

    if (_sort == 'oldest') {
      sortedTrips.sort((a, b) {
        return a.startDate.compareTo(b.startDate);
      });
    }

    return sortedTrips;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getLoggedUser();

      if (user == null) {
        await _logout();
        return;
      }

      final trips = await _tripService.getTrips();

      if (!mounted) return;

      setState(() {
        _username = user['username'];
        _profileImageUrl = user['profile_image_url'];
        _trips = trips;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Nie udało się pobrać wyjazdów.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _loadUser() async {
    final user = await _authService.getLoggedUser();

    if (!mounted) return;

    setState(() {
      _username = user?['username'];
      _profileImageUrl = user?['profile_image_url'];
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
  String? get _fullProfileImageUrl {
    if (_profileImageUrl == null ||
        _profileImageUrl!.trim().isEmpty) {
      return null;
    }

    if (_profileImageUrl!.startsWith('http://') ||
        _profileImageUrl!.startsWith('https://')) {
      return _profileImageUrl;
    }

    return '${AuthService.baseUrl}$_profileImageUrl';
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
          () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Future<void> _openAddTripScreen() async {
    final bool? wasSaved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const _TripFormBottomSheet();
      },
    );

    if (wasSaved == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _openEditTripScreen(Trip trip) async {
    final bool? wasSaved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TripFormBottomSheet(trip: trip);
      },
    );

    if (wasSaved == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _deleteTrip(Trip trip) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Usunąć wyjazd?'),
          content: Text(
            'Czy na pewno chcesz usunąć wyjazd "${trip.destinationName}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Usuń'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _tripService.deleteTrip(trip.id);

      if (!mounted) return;

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się usunąć wyjazdu.'),
        ),
      );
    }
  }

  List<Trip> _tripsByStatus(String status) {
    final trips = _filteredTrips.where((trip) => trip.status == status).toList();

    return _sortTrips(trips);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  void _clearFilters() {
    setState(() {
      _sort = 'newest';
      _selectedStatus = null;
      _dateFrom = null;
      _dateTo = null;
      _searchController.clear();
    });
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );

              await _loadData();
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
                      ),
                    ),
                    child: ClipOval(
                      child: _fullProfileImageUrl != null
                          ? Image.network(
                        _fullProfileImageUrl!,
                        width: 30,
                        height: 30,
                        fit: BoxFit.cover,
                        errorBuilder: (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return Icon(
                            Icons.person,
                            color: Colors.grey.shade500,
                            size: 22,
                          );
                        },
                      )
                          : Icon(
                        Icons.person,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
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

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Wyszukaj po nazwie lub celu',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: const Icon(
              Icons.tune,
              color: navy,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    if (!_showFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sortowanie',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _sort,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: 'newest',
                child: Text('Od najnowszych'),
              ),
              DropdownMenuItem(
                value: 'oldest',
                child: Text('Od najstarszych'),
              ),
              DropdownMenuItem(
                value: 'alpha',
                child: Text('Alfabetycznie'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _sort = value;
              });
            },
          ),
          const SizedBox(height: 14),
          const Text(
            'Status',
            style: TextStyle(
              color: navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Wszystkie'),
                selected: _selectedStatus == null,
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = null;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Aktualne'),
                selected: _selectedStatus == 'current',
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = 'current';
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Nadchodzące'),
                selected: _selectedStatus == 'upcoming',
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = 'upcoming';
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Archiwalne'),
                selected: _selectedStatus == 'archived',
                onSelected: (_) {
                  setState(() {
                    _selectedStatus = 'archived';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Data od',
                  value: _dateFrom == null ? null : _formatDate(_dateFrom!),
                  onTap: () async {
                    final selected = await _pickDate(_dateFrom);

                    if (selected != null) {
                      setState(() {
                        _dateFrom = selected;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'Data do',
                  value: _dateTo == null ? null : _formatDate(_dateTo!),
                  onTap: () async {
                    final selected = await _pickDate(_dateTo);

                    if (selected != null) {
                      setState(() {
                        _dateTo = selected;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _clearFilters,
              child: const Text('Wyczyść filtry'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Trip> trips) {
    if (trips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 2),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.blueGrey)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  style: TextStyle(
                    color: navy.withValues(alpha: 0.65),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Colors.blueGrey)),
            ],
          ),
          const SizedBox(height: 8),
          ...trips.map(
                (trip) => _TripCard(
              trip: trip,
              formatDate: _formatDate,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TripDetailsScreen(
                      trip: trip,
                    ),
                  ),
                );
              },
              onEdit: () {
                _openEditTripScreen(trip);
              },
              onDelete: () {
                _deleteTrip(trip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: navy,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    if (_filteredTrips.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'Brak wyjazdów do wyświetlenia.',
            style: TextStyle(
              color: navy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final currentTrips = _tripsByStatus('current');
    final upcomingTrips = _tripsByStatus('upcoming');
    final archivedTrips = _tripsByStatus('archived');

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          _buildSection('Aktualne', currentTrips),
          _buildSection('Nadchodzące', upcomingTrips),
          _buildSection('Archiwalne', archivedTrips),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTripScreen,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 34),
      ),
      bottomNavigationBar: Container(
        height: 58,
        color: navy,
        child: Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(
              child: Center(
                child: IconButton(
                  onPressed: _loadData,
                  icon: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
      body: SafeArea(
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
              _buildSearchAndFilter(),
              _buildFiltersPanel(),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }
}


class _TripFormBottomSheet extends StatefulWidget {
  final Trip? trip;

  const _TripFormBottomSheet({
    this.trip,
  });

  @override
  State<_TripFormBottomSheet> createState() => _TripFormBottomSheetState();
}

class _TripFormBottomSheetState extends State<_TripFormBottomSheet> {
  final TripService _tripService = TripService();
  final TextEditingController _tripNameController = TextEditingController();

  String? _originName;
  String? _originPlaceId;

  String? _destinationName;
  String? _destinationPlaceId;

  DateTime? _startDate;
  DateTime? _endDate;

  String? _errorMessage;
  bool _isSaving = false;

  static const Color navy = Color(0xFF263B63);

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();

    final trip = widget.trip;

    if (trip != null) {
      _originName = trip.originName;
      _originPlaceId = trip.originPlaceId;

      _destinationName = trip.destinationName;
      _destinationPlaceId = trip.destinationPlaceId;

      _startDate = trip.startDate;
      _endDate = trip.endDate;
      _tripNameController.text = trip.tripName;
    }
  }
  @override
  void dispose() {
    _tripNameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day.$month.$year';
  }

  Future<DateTime?> _pickDate(DateTime? initialDate) {
    final now = DateTime.now();

    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
  }

  Future<void> _saveTrip() async {
    final tripName = _tripNameController.text.trim();
    if (tripName.isEmpty ||
        _originName == null ||
        _destinationName == null ||
        _startDate == null ||
        _endDate == null) {
      setState(() {
        _errorMessage =
        'Uzupełnij wszystkie pola i wybierz miejsca z podpowiedzi.';
      });
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _errorMessage =
        'Data końca nie może być wcześniejsza niż data początku.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        await _tripService.updateTrip(

          tripId: widget.trip!.id,
          tripName: tripName,
          originName: _originName!,
          originPlaceId: _originPlaceId,
          destinationName: _destinationName!,
          destinationPlaceId: _destinationPlaceId,
          startDate: _startDate!,
          endDate: _endDate!,
        );
      } else {
        await _tripService.createTrip(
          tripName: tripName,
          originName: _originName!,
          originPlaceId: _originPlaceId,
          destinationName: _destinationName!,
          destinationPlaceId: _destinationPlaceId,
          startDate: _startDate!,
          endDate: _endDate!,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _isEditing
            ? 'Nie udało się edytować wyjazdu.'
            : 'Nie udało się dodać wyjazdu.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edytuj wyjazd' : 'Dodaj wyjazd';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                _TextInputField(
                  label: 'Nazwa wyjazdu',
                  hint: 'Np. Wakacje 2026',
                  controller: _tripNameController,
                ),
                const SizedBox(height: 14),

                _PlaceAutocompleteField(
                  key: ValueKey('origin-${widget.trip?.id ?? 'new'}'),
                  label: 'Skąd?',
                  hint: 'Wpisz miejsce rozpoczęcia',
                  initialName: _originName,
                  initialPlaceId: _originPlaceId,
                  onPlaceSelected: (place) {
                    setState(() {
                      _originName = place?.name;
                      _originPlaceId = place?.placeId;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _PlaceAutocompleteField(
                  key: ValueKey('destination-${widget.trip?.id ?? 'new'}'),
                  label: 'Dokąd?',
                  hint: 'Wpisz miejsce docelowe',
                  initialName: _destinationName,
                  initialPlaceId: _destinationPlaceId,
                  onPlaceSelected: (place) {
                    setState(() {
                      _destinationName = place?.name;
                      _destinationPlaceId = place?.placeId;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Od kiedy?',
                        value: _startDate == null
                            ? null
                            : _formatDate(_startDate!),
                        onTap: () async {
                          final selected = await _pickDate(_startDate);

                          if (selected != null && mounted) {
                            setState(() {
                              _startDate = selected;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                        label: 'Do kiedy?',
                        value:
                        _endDate == null ? null : _formatDate(_endDate!),
                        onTap: () async {
                          final selected = await _pickDate(_endDate);

                          if (selected != null && mounted) {
                            setState(() {
                              _endDate = selected;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveTrip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(_isEditing ? 'Zapisz' : 'Dodaj'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                        Navigator.pop(context, false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text('Anuluj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



class _PlaceAutocompleteField extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialName;
  final String? initialPlaceId;
  final ValueChanged<PlaceSuggestion?> onPlaceSelected;

  const _PlaceAutocompleteField({
    super.key,
    required this.label,
    required this.hint,
    required this.onPlaceSelected,
    this.initialName,
    this.initialPlaceId,
  });

  @override
  State<_PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState extends State<_PlaceAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final PlaceService _placeService = PlaceService();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _hasSelectedPlace = false;

  static const Color navy = Color(0xFF263B63);

  @override
  void initState() {
    super.initState();

    final initialName = widget.initialName;

    if (initialName != null && initialName.isNotEmpty) {
      _controller.text = initialName;
      _hasSelectedPlace = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String value) async {
    final text = value.trim();

    if (text.length < 3) {
      if (!mounted) return;

      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _placeService.autocompletePlaces(text);

      if (!mounted) return;

      setState(() {
        _suggestions = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _onTextChanged(String value) {
    setState(() {
      _hasSelectedPlace = false;
    });

    widget.onPlaceSelected(null);

    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 400),
          () {
        _searchPlaces(value);
      },
    );
  }

  void _selectPlace(PlaceSuggestion place) {
    setState(() {
      _hasSelectedPlace = true;
      _controller.text = place.name;
      _suggestions = [];
    });

    widget.onPlaceSelected(place);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: navy.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          onTap: () {
            if (_controller.text.trim().length >= 3) {
              _searchPlaces(_controller.text);
            }
          },
          onChanged: _onTextChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: Colors.grey.shade300,
            suffixIcon: _hasSelectedPlace
                ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
                : _isLoading
                ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            isDense: true,
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final place = _suggestions[index];

                return ListTile(
                  dense: true,
                  title: Text(
                    place.name,
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    place.country ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _selectPlace(place);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}



class _TripCard extends StatelessWidget {
  final Trip trip;
  final String Function(DateTime date) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.formatDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color navy = Color(0xFF263B63);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Container(
            padding: const EdgeInsets.all(12),
            height: 148,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trip.tripName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: navy,
                              size: 22,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit();
                              }
                              if (value == 'delete') {
                                onDelete();
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edytuj'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Usuń'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        '${formatDate(trip.startDate)} - ${formatDate(trip.endDate)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cel: ${trip.destinationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Z: ${trip.originName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 112,
                    height: 96,
                    color: Colors.blueGrey.shade100,
                    child: trip.photoUrl == null
                        ? const Icon(
                      Icons.landscape,
                      size: 46,
                      color: Colors.white,
                    )
                        : Image.network(
                      trip.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.landscape,
                          size: 46,
                          color: Colors.white,
                        );
                      },
                    ),
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

class _TextInputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _TextInputField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  static const Color navy = Color(0xFF263B63);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: navy.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade300,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
class _DateButton extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  static const Color navy = Color(0xFF263B63);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: navy.withValues(alpha: 0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Wybierz',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_month,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
