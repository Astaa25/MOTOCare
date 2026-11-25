/// Topik resmi tutorial perawatan mandiri sesuai PRD Bagian 5.5
class TutorialTopics {
  const TutorialTopics._();

  static const String all = 'Semua';
  static const String gantiOli = 'Ganti Oli';
  static const String rem = 'Rem';
  static const String ban = 'Ban';
  static const String aki = 'Aki';
  static const String rantai = 'Rantai';
  static const String busi = 'Busi';

  static const List<String> list = <String>[
    all,
    gantiOli,
    rem,
    ban,
    aki,
    rantai,
    busi,
  ];
}

/// Entitas Tutorial sesuai PRD Bagian 5.1 (Tabel tutorials)
class Tutorial {
  final String id;
  final String title;
  final String topic;
  final String youtubeUrl;
  final String? thumbnailUrl;
  final String? description;
  final bool isActive;
  final DateTime createdAt;

  const Tutorial({
    required this.id,
    required this.title,
    required this.topic,
    required this.youtubeUrl,
    this.thumbnailUrl,
    this.description,
    this.isActive = true,
    required this.createdAt,
  });

  /// Validasi URL YouTube sesuai check constraint PRD 5.1
  /// `^https://(www\.)?(youtube\.com|youtu\.be)/`
  static bool isValidYoutubeUrl(String url) {
    final regex = RegExp(r'^https://(www\.)?(youtube\.com|youtu\.be)/');
    return regex.hasMatch(url);
  }

  factory Tutorial.fromJson(Map<String, dynamic> json) {
    return Tutorial(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      topic: (json['category'] ?? json['topic'] ?? 'Umum') as String,
      youtubeUrl: (json['youtube_url'] ?? '') as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      description: json['description'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'topic': topic,
      'youtube_url': youtubeUrl,
      'thumbnail_url': thumbnailUrl,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Tutorial copyWith({
    String? id,
    String? title,
    String? topic,
    String? youtubeUrl,
    String? thumbnailUrl,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Tutorial(
      id: id ?? this.id,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
