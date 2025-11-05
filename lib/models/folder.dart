import 'score_item.dart';

class Folder {
  final String id;
  final String name;
  final String color; // 색상 코드 (예: "#FF5722")
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ScoreItem> scores;

  Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    List<ScoreItem>? scores,
  }) : scores = scores ?? [];

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#2196F3',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      scores: (json['scores'] as List<dynamic>?)
          ?.map((e) => ScoreItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'scores': scores.map((s) => s.toJson()).toList(),
    };
  }

  Folder copyWith({
    String? id,
    String? name,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ScoreItem>? scores,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scores: scores ?? this.scores,
    );
  }
}

