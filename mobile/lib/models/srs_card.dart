class SRSCard {
  final String id;
  final String front;
  final String back;
  final SRSCardMetadata metadata;

  SRSCard({
    required this.id,
    required this.front,
    required this.back,
    required this.metadata,
  });

  factory SRSCard.fromJson(Map<String, dynamic> json) {
    return SRSCard(
      id: json['content']['id'],
      front: json['content']['front'],
      back: json['content']['back'],
      metadata: SRSCardMetadata.fromJson(json['metadata']),
    );
  }
}

class SRSCardMetadata {
  final String cardId;
  final int interval;
  final double easeFactor;
  final DateTime nextReview;

  SRSCardMetadata({
    required this.cardId,
    required this.interval,
    required this.easeFactor,
    required this.nextReview,
  });

  factory SRSCardMetadata.fromJson(Map<String, dynamic> json) {
    return SRSCardMetadata(
      cardId: json['card_id'],
      interval: json['interval'],
      easeFactor: json['ease_factor'],
      nextReview: DateTime.parse(json['next_review']),
    );
  }
}
