class TagPopularity {
  final int id;
  final String tag;
  final int percentage;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  TagPopularity({
    required this.id,
    required this.tag,
    required this.percentage,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TagPopularity.fromJson(Map<String, dynamic> json) {
    return TagPopularity(
      id: json['id'] as int,
      tag: json['tag'] as String,
      percentage: json['percentage'] as int,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'percentage': percentage,
      'isActive': isActive,
    };
  }

  TagPopularity copyWith({
    int? id,
    String? tag,
    int? percentage,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return TagPopularity(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      percentage: percentage ?? this.percentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CreateTagPopularityRequest {
  final String tag;
  final int percentage;
  final bool isActive;

  CreateTagPopularityRequest({
    required this.tag,
    required this.percentage,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'percentage': percentage,
      'isActive': isActive,
    };
  }
}

class UpdateTagPopularityRequest {
  final String tag;
  final int percentage;
  final bool isActive;

  UpdateTagPopularityRequest({
    required this.tag,
    required this.percentage,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'percentage': percentage,
      'isActive': isActive,
    };
  }
}
