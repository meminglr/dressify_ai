import 'package:equatable/equatable.dart';

/// Ürün yorumu modeli
/// Trendyol API'den gelen yorum verilerini temsil eder
class Review extends Equatable {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  /// JSON'dan Review nesnesi oluşturur
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Anonim',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  /// Review nesnesini JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_name': userName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Belirli alanları güncelleyerek yeni Review nesnesi oluşturur
  Review copyWith({
    String? id,
    String? userName,
    double? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userName,
        rating,
        comment,
        createdAt,
      ];

  @override
  bool get stringify => true;
}
