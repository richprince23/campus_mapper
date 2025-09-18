class University {
  final String id;
  final String name;
  final String shortName;
  final bool isActive;

  const University({
    required this.id,
    required this.name,
    required this.shortName,
    this.isActive = true,
  });

  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'is_active': isActive,
    };
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is University && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}