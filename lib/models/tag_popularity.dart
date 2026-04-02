class TagPopularity {
  final int id;
  final String tag;
  final int percentage;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;
  final String? category;

  TagPopularity({
    required this.id,
    required this.tag,
    required this.percentage,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.category,
  });

  factory TagPopularity.fromJson(Map<String, dynamic> json) {
    return TagPopularity(
      id: json['id'] as int,
      tag: json['tag'] as String,
      percentage: json['percentage'] as int,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag': tag,
      'percentage': percentage,
      'isActive': isActive,
      'category': category,
    };
  }

  TagPopularity copyWith({
    int? id,
    String? tag,
    int? percentage,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    String? category,
  }) {
    return TagPopularity(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      percentage: percentage ?? this.percentage,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}

class CreateTagPopularityRequest {
  final String tag;
  final int percentage;
  final bool isActive;
  final String? category;

  CreateTagPopularityRequest({
    required this.tag,
    required this.percentage,
    this.isActive = true,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'percentage': percentage,
      'isActive': isActive,
      'category': category,
    };
  }
}

class UpdateTagPopularityRequest {
  final String tag;
  final int percentage;
  final bool isActive;
  final String? category;

  UpdateTagPopularityRequest({
    required this.tag,
    required this.percentage,
    this.isActive = true,
    this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'percentage': percentage,
      'isActive': isActive,
      'category': category,
    };
  }
}

class SyncResult {
  final int rulesProcessed;
  final int totalImagesUpdated;

  SyncResult({required this.rulesProcessed, required this.totalImagesUpdated});

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      rulesProcessed: json['rulesProcessed'] as int? ?? 0,
      totalImagesUpdated: json['totalImagesUpdated'] as int? ?? 0,
    );
  }
}

class TagSearchResult {
  final String tag;
  final String origin;

  TagSearchResult({required this.tag, required this.origin});

  factory TagSearchResult.fromJson(Map<String, dynamic> json) {
    return TagSearchResult(
      tag: json['tag'] as String,
      origin: json['origin'] as String,
    );
  }
}
