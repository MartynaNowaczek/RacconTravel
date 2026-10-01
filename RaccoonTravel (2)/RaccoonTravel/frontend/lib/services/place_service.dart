import 'dart:convert';
import '../models/place_suggestion.dart';
import '../services/place_service.dart';
import 'package:http/http.dart' as http;

import '../models/place_suggestion.dart';
import 'auth_service.dart';

class PlaceService {
  Future<List<PlaceSuggestion>> autocompletePlaces(String input) async {
    final text = input.trim();

    if (text.length < 3) {
      return [];
    }

    final uri = Uri.parse('${AuthService.baseUrl}/places/autocomplete')
        .replace(queryParameters: {
      'input': text,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data
          .map((json) => PlaceSuggestion.fromJson(json))
          .toList();
    }

    throw Exception('Nie udało się pobrać podpowiedzi miejsc.');
  }
}