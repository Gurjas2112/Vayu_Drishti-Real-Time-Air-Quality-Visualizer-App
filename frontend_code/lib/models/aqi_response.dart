import 'latest_aqi.dart';
import 'forecast_entry.dart';
import 'health_recommendation.dart';

class AqiResponse {
  final LatestAqi latest;
  final List<ForecastEntry> forecast;
  final HealthRecommendation health;

  AqiResponse({
    required this.latest,
    required this.forecast,
    required this.health,
  });

  factory AqiResponse.fromJson(Map<String, dynamic> json) {
    return AqiResponse(
      latest: LatestAqi.fromJson(json['latest'] as Map<String, dynamic>),
      forecast: (json['forecast'] as List<dynamic>)
          .map((f) => ForecastEntry.fromJson(f as Map<String, dynamic>))
          .toList(),
      health: HealthRecommendation.fromJson(
        json['health'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest': latest.toJson(),
      'forecast': forecast.map((f) => f.toJson()).toList(),
      'health': health.toJson(),
    };
  }

  @override
  String toString() {
    return 'AqiResponse(station: ${latest.stationName}, aqi: ${latest.aqi}, forecast: ${forecast.length} entries)';
  }
}
