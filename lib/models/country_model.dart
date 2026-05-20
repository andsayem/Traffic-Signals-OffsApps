class CountryModel {
  final String id;
  final String name;
  final String flagEmoji;
  final String description;
  final String drivingSide;
  final String emergencyNumber;
  final String speedLimitCity;
  final String speedLimitHighway;
  final String alcoholLimit;
  final List<String> tips;

  const CountryModel({
    required this.id,
    required this.name,
    required this.flagEmoji,
    required this.description,
    required this.drivingSide,
    required this.emergencyNumber,
    required this.speedLimitCity,
    required this.speedLimitHighway,
    required this.alcoholLimit,
    required this.tips,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    return CountryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      flagEmoji: json['flagEmoji'] as String,
      description: json['description'] as String,
      drivingSide: json['drivingSide'] as String,
      emergencyNumber: json['emergencyNumber'] as String,
      speedLimitCity: json['speedLimitCity'] as String,
      speedLimitHighway: json['speedLimitHighway'] as String,
      alcoholLimit: json['alcoholLimit'] as String,
      tips: List<String>.from(json['tips'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'flagEmoji': flagEmoji,
      'description': description,
      'drivingSide': drivingSide,
      'emergencyNumber': emergencyNumber,
      'speedLimitCity': speedLimitCity,
      'speedLimitHighway': speedLimitHighway,
      'alcoholLimit': alcoholLimit,
      'tips': tips,
    };
  }
}
