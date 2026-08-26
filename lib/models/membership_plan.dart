/// A purchasable premium-membership pass — a fixed term (e.g. 90 days),
/// not an auto-renewing subscription. The `durationDays` shape is
/// deliberate: a future recurring subscription can reuse this same plan
/// document with an `autoRenew` flag added, without changing the schema.
class MembershipPlan {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final String currency;
  final int durationDays;
  final List<String> perks;
  final bool active;

  const MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.durationDays,
    required this.perks,
    required this.active,
  });

  double get priceMajor => priceCents / 100;

  factory MembershipPlan.fromMap(String id, Map<String, dynamic> map) {
    return MembershipPlan(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priceCents: map['priceCents'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'bgn',
      durationDays: map['durationDays'] as int? ?? 30,
      perks: (map['perks'] as List?)?.map((e) => e as String).toList() ?? [],
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'priceCents': priceCents,
      'currency': currency,
      'durationDays': durationDays,
      'perks': perks,
      'active': active,
    };
  }

  MembershipPlan copyWith({
    String? name,
    String? description,
    int? priceCents,
    int? durationDays,
    List<String>? perks,
    bool? active,
  }) {
    return MembershipPlan(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      currency: currency,
      durationDays: durationDays ?? this.durationDays,
      perks: perks ?? this.perks,
      active: active ?? this.active,
    );
  }
}
