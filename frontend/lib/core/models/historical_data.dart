class HistoricalAirQualityData {
  final String locationName;
  final List<AirQualityDataPoint> dataPoints;
  final DateTime startDate;
  final DateTime endDate;

  HistoricalAirQualityData({
    required this.locationName,
    required this.dataPoints,
    required this.startDate,
    required this.endDate,
  });

  factory HistoricalAirQualityData.fromJson(Map<String, dynamic> json) {
    final dataPointsList = (json['dataPoints'] as List)
        .map((e) => AirQualityDataPoint.fromJson(e))
        .toList();

    return HistoricalAirQualityData(
      locationName: json['locationName'],
      dataPoints: dataPointsList,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  // Generate mock historical data for demonstration
  factory HistoricalAirQualityData.mock(
    String locationName,
    double latitude,
    double longitude,
    int daysBack,
  ) {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: daysBack));
    final dataPoints = <AirQualityDataPoint>[];

    for (int i = 0; i < daysBack; i++) {
      final date = startDate.add(Duration(days: i));
      final baseAqi = 75 + (i % 50); // Simulate varying AQI

      dataPoints.add(
        AirQualityDataPoint(
          timestamp: date,
          aqi: baseAqi,
          pm25: baseAqi * 0.4,
          pm10: baseAqi * 0.6,
          no2: baseAqi * 0.3,
          o3: baseAqi * 0.8,
          so2: baseAqi * 0.2,
          co: baseAqi * 0.1,
        ),
      );
    }

    return HistoricalAirQualityData(
      locationName: locationName,
      dataPoints: dataPoints,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

class AirQualityDataPoint {
  final DateTime timestamp;
  final int aqi;
  final double pm25;
  final double pm10;
  final double no2;
  final double o3;
  final double so2;
  final double co;

  AirQualityDataPoint({
    required this.timestamp,
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.co,
  });

  factory AirQualityDataPoint.fromJson(Map<String, dynamic> json) {
    return AirQualityDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      aqi: json['aqi'],
      pm25: json['pm25'].toDouble(),
      pm10: json['pm10'].toDouble(),
      no2: json['no2'].toDouble(),
      o3: json['o3'].toDouble(),
      so2: json['so2'].toDouble(),
      co: json['co'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'aqi': aqi,
      'pm25': pm25,
      'pm10': pm10,
      'no2': no2,
      'o3': o3,
      'so2': so2,
      'co': co,
    };
  }
}
