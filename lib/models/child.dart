class Child {
  final String id;
  final String name;
  final DateTime birthDate;
  final String? notes;

  const Child({
    required this.id,
    required this.name,
    required this.birthDate,
    this.notes,
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 +
        (now.month - birthDate.month) -
        (now.day < birthDate.day ? 1 : 0);
  }

  factory Child.fromMap(String id, Map<String, dynamic> map) {
    return Child(
      id: id,
      name: map['name'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'notes': notes,
    };
  }

  Child copyWith({String? name, DateTime? birthDate, String? notes}) {
    return Child(
      id: id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      notes: notes ?? this.notes,
    );
  }
}
