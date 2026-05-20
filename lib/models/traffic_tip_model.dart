class TrafficTipModel {
  final String id;
  final String title;
  final String description;
  final String category; // safety, pedestrian, defensive, signs
  final String iconName; // e.g. shield, directions_walk, speed, etc.

  const TrafficTipModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
  });

  factory TrafficTipModel.fromJson(Map<String, dynamic> json) {
    return TrafficTipModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      iconName: json['iconName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'iconName': iconName,
    };
  }
}
