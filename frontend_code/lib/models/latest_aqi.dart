import 'pollutant_reading.dart';

class LatestAqi {
  final String stationId;
  final String stationName;
  final double lat;
  final double lon;
  final int aqi;
  final List<PollutantReading> pollutants;
  final DateTime timestamp;

  LatestAqi({
    required this.stationId,
    required this.stationName,
    required this.lat,
    required this.lon,
    required this.aqi,
    required this.pollutants,
    required this.timestamp,
  });

  factory LatestAqi.fromJson(Map<String, dynamic> json) {
    return LatestAqi(
      stationId: json['stationId'] as String,
      stationName: json['stationName'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      aqi: json['aqi'] as int,
      pollutants: (json['pollutants'] as List<dynamic>)
          .map((p) => PollutantReading.fromJson(p as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'lat': lat,
      'lon': lon,
      'aqi': aqi,
      'pollutants': pollutants.map((p) => p.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
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

  Map<String, double> get pollutantsMap {
    final Map<String, double> map = {};
    for (final pollutant in pollutants) {
      map[pollutant.name] = pollutant.value;
    }
    return map;
  }

  @override
  String toString() {
    return 'LatestAqi(stationId: $stationId, stationName: $stationName, aqi: $aqi, category: $aqiCategory)';
  }
}
