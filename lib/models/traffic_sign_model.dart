class TrafficSignModel {
  final String id;
  final String category; // warning, regulatory, mandatory, information, signal_light
  final String name;
  final String meaning;
  final String description;
  final String usageInstructions;
  final Map<String, String> countrySpecificInfo; // Map of countryId -> specific detail override

  const TrafficSignModel({
    required this.id,
    required this.category,
    required this.name,
    required this.meaning,
    required this.description,
    required this.usageInstructions,
    required this.countrySpecificInfo,
  });

  factory TrafficSignModel.fromJson(Map<String, dynamic> json) {
    return TrafficSignModel(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      meaning: json['meaning'] as String,
      description: json['description'] as String,
      usageInstructions: json['usageInstructions'] as String,
      countrySpecificInfo: Map<String, String>.from(json['countrySpecificInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'name': name,
      'meaning': meaning,
      'description': description,
      'usageInstructions': usageInstructions,
      'countrySpecificInfo': countrySpecificInfo,
    };
  }
}
