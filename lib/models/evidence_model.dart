class EvidenceModel {
  final String id;
  final String tradeId;
  final String farmerId;
  final String role; // 'sending' or 'receiving'
  final String productName; // which product this evidence is for
  final String? photoUrl;
  final String? photoHash;
  final double aiQualityScore;
  final String conditionTag; // Excellent, Good, Average, Poor
  final double freshnessScore;
  final double damageScore;
  final double colorScore;
  final double sizeScore;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  EvidenceModel({
    required this.id,
    required this.tradeId,
    required this.farmerId,
    this.role = 'sending',
    this.productName = '',
    this.photoUrl,
    this.photoHash,
    this.aiQualityScore = 0.0,
    this.conditionTag = 'Good',
    this.freshnessScore = 0.0,
    this.damageScore = 0.0,
    this.colorScore = 0.0,
    this.sizeScore = 0.0,
    this.latitude = 0.0,
    this.longitude = 0.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tradeId': tradeId,
      'farmerId': farmerId,
      'role': role,
      'productName': productName,
      'photoUrl': photoUrl,
      'photoHash': photoHash,
      'aiQualityScore': aiQualityScore,
      'conditionTag': conditionTag,
      'freshnessScore': freshnessScore,
      'damageScore': damageScore,
      'colorScore': colorScore,
      'sizeScore': sizeScore,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory EvidenceModel.fromMap(Map<String, dynamic> map) {
    return EvidenceModel(
      id: map['id'] ?? '',
      tradeId: map['tradeId'] ?? '',
      farmerId: map['farmerId'] ?? '',
      role: map['role'] ?? 'sending',
      productName: map['productName'] ?? '',
      photoUrl: map['photoUrl'],
      photoHash: map['photoHash'],
      aiQualityScore: (map['aiQualityScore'] ?? 0.0).toDouble(),
      conditionTag: map['conditionTag'] ?? 'Good',
      freshnessScore: (map['freshnessScore'] ?? 0.0).toDouble(),
      damageScore: (map['damageScore'] ?? 0.0).toDouble(),
      colorScore: (map['colorScore'] ?? 0.0).toDouble(),
      sizeScore: (map['sizeScore'] ?? 0.0).toDouble(),
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
    );
  }
}
