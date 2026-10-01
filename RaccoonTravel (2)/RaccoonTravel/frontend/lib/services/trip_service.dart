import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip.dart';
import 'auth_service.dart';

class TripService {
  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();

    if (token == null) {
      throw Exception('Brak tokenu logowania.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  Future<List<Trip>> getTrips({
    String? search,
    String? status,
    String sort = 'newest',
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final queryParameters = <String, String>{
      'sort': sort,
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status;
    }

    if (dateFrom != null) {
      queryParameters['date_from'] = _formatDateForApi(dateFrom);
    }

    if (dateTo != null) {
      queryParameters['date_to'] = _formatDateForApi(dateTo);
    }

    final uri = Uri.parse('${AuthService.baseUrl}/trips').replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Trip.fromJson(json)).toList();
    }

    throw Exception('Nie udało się pobrać wyjazdów.');
  }

  Map<String, dynamic> _tripBody({
    required String tripName,
    required String originName,
    required String destinationName,
    required DateTime startDate,
    required DateTime endDate,
    String? originPlaceId,
    String? destinationPlaceId,
  }) {
    return {
      'trip_name': tripName,
      'origin_name': originName,
      'origin_place_id': originPlaceId,
      'destination_name': destinationName,
      'destination_place_id': destinationPlaceId,
      'start_date': _formatDateForApi(startDate),
      'end_date': _formatDateForApi(endDate),
    };
  }

  Future<void> createTrip({
    required String tripName,
    required String originName,
    required String destinationName,
    required DateTime startDate,
    required DateTime endDate,
    String? originPlaceId,
    String? destinationPlaceId,
  }) async {
    final uri = Uri.parse('${AuthService.baseUrl}/trips');

    final response = await http.post(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(
        _tripBody(
          tripName: tripName,
          originName: originName,
          originPlaceId: originPlaceId,
          destinationName: destinationName,
          destinationPlaceId: destinationPlaceId,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Nie udało się dodać wyjazdu. Status: ${response.statusCode}, body: ${response.body}',
      );
    }
  }

  Future<void> updateTrip({
    required int tripId,
    required String tripName,
    required String originName,
    required String destinationName,
    required DateTime startDate,
    required DateTime endDate,
    String? originPlaceId,
    String? destinationPlaceId,
  }) async {
    final uri = Uri.parse('${AuthService.baseUrl}/trips/$tripId');

    final response = await http.put(
      uri,
      headers: await _getHeaders(),
      body: jsonEncode(
        _tripBody(
          tripName: tripName,
          originName: originName,
          originPlaceId: originPlaceId,
          destinationName: destinationName,
          destinationPlaceId: destinationPlaceId,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Nie udało się edytować wyjazdu. Status: ${response.statusCode}, body: ${response.body}',
      );
    }
  }

  Future<void> deleteTrip(int tripId) async {
    final uri = Uri.parse('${AuthService.baseUrl}/trips/$tripId');

    final response = await http.delete(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    throw Exception(
      'Nie udało się usunąć wyjazdu. Status: ${response.statusCode}, body: ${response.body}',
    );
  }
}