import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:open_meteo_api/open_meteo_api.dart';

/// Exception thrown when locationSearch fails.
class LocationRequestFailure implements Exception {}

/// Exception thrown when the provided location is not found.
class LocationNotFoundFailure implements Exception {}

/// Exception thrown when getWeather fails.
class WeatherRequestFailure implements Exception {}

/// Exception thrown when weather for provided location is not found.
class WeatherNotFoundFailure implements Exception {}

class OpenMeteoApiClient {
  OpenMeteoApiClient({
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _baseUrlWeather = 'api.open-meteo.com';
  static const _baseUrlGeocoding = 'geocoding-api.open-meteo.com';

  /// Finds a [Location] `/v1/search/?name=(query)`.
  Future<Location> locationSearch(String query) async {
    Map<String, String> queryParameters = {
      'name': query,
      'count': '1',
    };

    final locationRequest = Uri.https(
      _baseUrlGeocoding,
      '/v1/search',
      queryParameters,
    );

    final http.Response locationResponse =
        await _httpClient.get(locationRequest);

    if (locationResponse.statusCode != 200) throw LocationRequestFailure();

    final bodyJson = jsonDecode(locationResponse.body) as Map<String, dynamic>;

    if (!bodyJson.containsKey('results')) throw LocationNotFoundFailure();

    final results = bodyJson['results'] as List;

    if (results.isEmpty) throw LocationNotFoundFailure();

    return Location.fromJson(results.first as Map<String, dynamic>);
  }

  /// Fetches [Weather] for a given [latitude] and [longitude].
  Future<Weather> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    Map<String, String> queryParameters = {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current_weather': 'true',
    };

    final weatherRequest = Uri.https(
      _baseUrlWeather,
      'v1/forecast',
      queryParameters,
    );

    final weatherResponse = await _httpClient.get(weatherRequest);

    if (weatherResponse.statusCode != 200) throw WeatherRequestFailure();

    final bodyJson = jsonDecode(weatherResponse.body) as Map<String, dynamic>;

    if (!bodyJson.containsKey('current_weather')) {
      throw WeatherNotFoundFailure();
    }

    final weatherJson = bodyJson['current_weather'] as Map<String, dynamic>;

    return Weather.fromJson(weatherJson);
  }
}
