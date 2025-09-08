class HealthAdvisory {
  final String locationName;
  final int currentAQI;
  final String category;
  final List<String> generalRecommendations;
  final List<String> sensitiveGroupRecommendations;
  final List<String> outdoorActivityRecommendations;
  final String maskRecommendation;
  final String exerciseRecommendation;
  final bool shouldUseAirPurifier;
  final bool shouldCloseWindows;
  final String healthRiskLevel;
  final Map<String, String> pollutantSpecificAdvice;

  HealthAdvisory({
    required this.locationName,
    required this.currentAQI,
    required this.category,
    required this.generalRecommendations,
    required this.sensitiveGroupRecommendations,
    required this.outdoorActivityRecommendations,
    required this.maskRecommendation,
    required this.exerciseRecommendation,
    required this.shouldUseAirPurifier,
    required this.shouldCloseWindows,
    required this.healthRiskLevel,
    required this.pollutantSpecificAdvice,
  });

  factory HealthAdvisory.fromAQI(
    String locationName,
    int aqi,
    Map<String, double> pollutants,
  ) {
    return HealthAdvisory(
      locationName: locationName,
      currentAQI: aqi,
      category: _getAQICategory(aqi),
      generalRecommendations: _getGeneralRecommendations(aqi),
      sensitiveGroupRecommendations: _getSensitiveGroupRecommendations(aqi),
      outdoorActivityRecommendations: _getOutdoorActivityRecommendations(aqi),
      maskRecommendation: _getMaskRecommendation(aqi),
      exerciseRecommendation: _getExerciseRecommendation(aqi),
      shouldUseAirPurifier: aqi > 100,
      shouldCloseWindows: aqi > 150,
      healthRiskLevel: _getHealthRiskLevel(aqi),
      pollutantSpecificAdvice: _getPollutantSpecificAdvice(pollutants),
    );
  }

  static String _getAQICategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive Groups';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  static List<String> _getGeneralRecommendations(int aqi) {
    if (aqi <= 50) {
      return [
        'Air quality is excellent! Perfect time for outdoor activities.',
        'Great day to open windows and enjoy fresh air.',
        'Ideal conditions for exercise and outdoor sports.',
      ];
    } else if (aqi <= 100) {
      return [
        'Air quality is good for most people.',
        'Normal outdoor activities are fine.',
        'Consider reducing prolonged outdoor exertion if you\'re unusually sensitive.',
      ];
    } else if (aqi <= 150) {
      return [
        'Air quality is acceptable for most people.',
        'Sensitive individuals should limit prolonged outdoor exertion.',
        'Consider shorter outdoor activities.',
      ];
    } else if (aqi <= 200) {
      return [
        'Everyone should limit prolonged outdoor exertion.',
        'Children and elderly should be especially careful.',
        'Consider indoor activities instead.',
      ];
    } else if (aqi <= 300) {
      return [
        'Avoid all outdoor activities.',
        'Stay indoors as much as possible.',
        'Keep windows and doors closed.',
      ];
    } else {
      return [
        'Health emergency - avoid all outdoor exposure.',
        'Stay indoors and seal off outdoor air.',
        'Consider leaving the area if possible.',
      ];
    }
  }

  static List<String> _getSensitiveGroupRecommendations(int aqi) {
    if (aqi <= 50) {
      return [
        'No special precautions needed.',
        'Enjoy outdoor activities normally.',
      ];
    } else if (aqi <= 100) {
      return [
        'People with respiratory conditions should be aware.',
        'Limit prolonged outdoor exertion if symptoms occur.',
      ];
    } else if (aqi <= 150) {
      return [
        'Children, elderly, and people with heart/lung disease should limit outdoor activities.',
        'Watch for symptoms like coughing or shortness of breath.',
        'Consider rescheduling outdoor plans.',
      ];
    } else if (aqi <= 200) {
      return [
        'Children, elderly, and people with heart/lung disease should avoid outdoor activities.',
        'Everyone else should limit outdoor exertion.',
        'Seek medical attention if symptoms persist.',
      ];
    } else if (aqi <= 300) {
      return [
        'Children, elderly, and people with heart/lung disease should remain indoors.',
        'Everyone should avoid outdoor activities.',
        'Consider leaving the area if health conditions worsen.',
      ];
    } else {
      return [
        'Emergency conditions for all sensitive groups.',
        'Seek immediate medical attention if experiencing symptoms.',
        'Evacuate if possible.',
      ];
    }
  }

  static List<String> _getOutdoorActivityRecommendations(int aqi) {
    if (aqi <= 50) {
      return [
        'All outdoor activities recommended',
        'Perfect for sports and exercise',
      ];
    } else if (aqi <= 100) {
      return [
        'Most outdoor activities are fine',
        'Reduce intensity if sensitive',
      ];
    } else if (aqi <= 150) {
      return [
        'Reduce prolonged outdoor activities',
        'Shorter duration activities preferred',
      ];
    } else if (aqi <= 200) {
      return [
        'Avoid prolonged outdoor activities',
        'Indoor alternatives recommended',
      ];
    } else if (aqi <= 300) {
      return ['Avoid all outdoor activities', 'Stay indoors'];
    } else {
      return ['No outdoor activities', 'Emergency indoor shelter'];
    }
  }

  static String _getMaskRecommendation(int aqi) {
    if (aqi <= 50) return 'No mask needed';
    if (aqi <= 100) return 'Mask optional for sensitive individuals';
    if (aqi <= 150) return 'N95 mask recommended for outdoor activities';
    if (aqi <= 200) return 'N95 mask required when going outside';
    if (aqi <= 300) return 'N95 mask essential, limit outdoor time';
    return 'N95 or P100 mask required, avoid outdoor exposure';
  }

  static String _getExerciseRecommendation(int aqi) {
    if (aqi <= 50) return 'All exercise activities recommended';
    if (aqi <= 100) return 'Normal exercise, monitor for symptoms';
    if (aqi <= 150) {
      return 'Reduce exercise intensity, prefer indoor activities';
    }
    if (aqi <= 200) return 'Light exercise only, indoors preferred';
    if (aqi <= 300) return 'Avoid exercise, rest recommended';
    return 'No exercise, complete rest required';
  }

  static String _getHealthRiskLevel(int aqi) {
    if (aqi <= 50) return 'Low';
    if (aqi <= 100) return 'Low to Moderate';
    if (aqi <= 150) return 'Moderate';
    if (aqi <= 200) return 'High';
    if (aqi <= 300) return 'Very High';
    return 'Emergency';
  }

  static Map<String, String> _getPollutantSpecificAdvice(
    Map<String, double> pollutants,
  ) {
    final advice = <String, String>{};

    final pm25 = pollutants['pm2_5'] ?? 0;
    if (pm25 > 35) {
      advice['PM2.5'] =
          'Fine particles detected. Use air purifier and avoid outdoor exercise.';
    } else if (pm25 > 12) {
      advice['PM2.5'] =
          'Moderate fine particle levels. Consider limiting outdoor time.';
    }

    final pm10 = pollutants['pm10'] ?? 0;
    if (pm10 > 154) {
      advice['PM10'] =
          'High coarse particle levels. Avoid dusty areas and wear mask outdoors.';
    } else if (pm10 > 54) {
      advice['PM10'] =
          'Elevated coarse particles. Limit outdoor activities in dusty areas.';
    }

    final no2 = pollutants['no2'] ?? 0;
    if (no2 > 100) {
      advice['NO₂'] =
          'High nitrogen dioxide levels. Avoid traffic areas and busy roads.';
    } else if (no2 > 53) {
      advice['NO₂'] =
          'Moderate NO₂ levels. Limit time near traffic and industrial areas.';
    }

    final o3 = pollutants['o3'] ?? 0;
    if (o3 > 164) {
      advice['O₃'] =
          'High ozone levels. Avoid outdoor activities during peak sun hours.';
    } else if (o3 > 124) {
      advice['O₃'] =
          'Moderate ozone levels. Reduce outdoor exercise during afternoon.';
    }

    final so2 = pollutants['so2'] ?? 0;
    if (so2 > 75) {
      advice['SO₂'] =
          'High sulfur dioxide. Avoid industrial areas and use air purifier.';
    }

    final co = pollutants['co'] ?? 0;
    if (co > 12) {
      advice['CO'] =
          'Elevated carbon monoxide. Ensure good ventilation indoors.';
    }

    return advice;
  }

  List<String> getAllRecommendations() {
    final allRecommendations = <String>[];
    allRecommendations.addAll(generalRecommendations);
    allRecommendations.addAll(sensitiveGroupRecommendations);
    allRecommendations.addAll(outdoorActivityRecommendations);

    if (maskRecommendation != 'No mask needed') {
      allRecommendations.add(maskRecommendation);
    }

    if (exerciseRecommendation != 'All exercise activities recommended') {
      allRecommendations.add('Exercise: $exerciseRecommendation');
    }

    if (shouldUseAirPurifier) {
      allRecommendations.add('Use air purifier indoors');
    }

    if (shouldCloseWindows) {
      allRecommendations.add('Keep windows and doors closed');
    }

    return allRecommendations;
  }

  factory HealthAdvisory.fromJson(Map<String, dynamic> json) {
    return HealthAdvisory(
      locationName: json['locationName'],
      currentAQI: json['currentAQI'],
      category: json['category'],
      generalRecommendations: List<String>.from(json['generalRecommendations']),
      sensitiveGroupRecommendations: List<String>.from(
        json['sensitiveGroupRecommendations'],
      ),
      outdoorActivityRecommendations: List<String>.from(
        json['outdoorActivityRecommendations'],
      ),
      maskRecommendation: json['maskRecommendation'],
      exerciseRecommendation: json['exerciseRecommendation'],
      shouldUseAirPurifier: json['shouldUseAirPurifier'],
      shouldCloseWindows: json['shouldCloseWindows'],
      healthRiskLevel: json['healthRiskLevel'],
      pollutantSpecificAdvice: Map<String, String>.from(
        json['pollutantSpecificAdvice'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'currentAQI': currentAQI,
      'category': category,
      'generalRecommendations': generalRecommendations,
      'sensitiveGroupRecommendations': sensitiveGroupRecommendations,
      'outdoorActivityRecommendations': outdoorActivityRecommendations,
      'maskRecommendation': maskRecommendation,
      'exerciseRecommendation': exerciseRecommendation,
      'shouldUseAirPurifier': shouldUseAirPurifier,
      'shouldCloseWindows': shouldCloseWindows,
      'healthRiskLevel': healthRiskLevel,
      'pollutantSpecificAdvice': pollutantSpecificAdvice,
    };
  }
}
