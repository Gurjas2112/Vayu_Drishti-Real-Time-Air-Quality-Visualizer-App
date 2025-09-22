import 'pollutant_reading.dart';

class ForecastEntry {
  final DateTime timestamp;
  final int aqi;
  final List<PollutantReading> pollutants;

  ForecastEntry({
    required this.timestamp,
    required this.aqi,
    required this.pollutants,
  });

  factory ForecastEntry.fromJson(Map<String, dynamic> json) {
    return ForecastEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      aqi: json['aqi'] as int,
      pollutants:
          (json['pollutants'] as List<dynamic>?)
              ?.map((p) => PollutantReading.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'aqi': aqi,
      'pollutants': pollutants.map((p) => p.toJson()).toList(),
    };
  }

  String get aqiCategory {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Fair';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'Poor';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }

  @override
  String toString() {
    return 'ForecastEntry(timestamp: $timestamp, aqi: $aqi, category: $aqiCategory)';
  }
}
