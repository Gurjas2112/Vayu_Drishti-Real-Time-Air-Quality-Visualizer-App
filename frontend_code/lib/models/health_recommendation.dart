class HealthRecommendation {
  final String category;
  final String description;
  final List<String> recommendations;

  HealthRecommendation({
    required this.category,
    required this.description,
    required this.recommendations,
  });

  factory HealthRecommendation.fromJson(Map<String, dynamic> json) {
    return HealthRecommendation(
      category: json['category'] as String,
      description: json['description'] as String,
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((r) => r as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'description': description,
      'recommendations': recommendations,
    };
  }

  @override
  String toString() {
    return 'HealthRecommendation(category: $category, recommendations: ${recommendations.length})';
  }
}
