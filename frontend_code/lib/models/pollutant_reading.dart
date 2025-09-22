class PollutantReading {
  final String name;
  final double value;

  PollutantReading({required this.name, required this.value});

  factory PollutantReading.fromJson(Map<String, dynamic> json) {
    return PollutantReading(
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'value': value};
  }

  @override
  String toString() {
    return 'PollutantReading(name: $name, value: $value)';
  }
}
