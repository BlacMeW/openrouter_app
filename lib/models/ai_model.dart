class AIModel {
  final String id;
  final String name;
  final String description;
  final String provider;
  final bool isDefault;

  const AIModel({
    required this.id,
    required this.name,
    required this.description,
    required this.provider,
    this.isDefault = false,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      provider: json['provider'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'provider': provider,
      'isDefault': isDefault,
    };
  }

  @override
  String toString() {
    return 'AIModel(id: $id, name: $name, provider: $provider)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIModel &&
        other.id == id &&
        other.name == name &&
        other.provider == provider;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ provider.hashCode;
}