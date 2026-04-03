class Expense {
  final int? id;
  final String date;
  final String description;
  final String category;
  final double amount;
  final String? imagePath;
  final String? notes;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.amount,
    this.imagePath,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'category': category,
      'amount': amount,
      'image_path': imagePath,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      date: map['date'],
      description: map['description'],
      category: map['category'],
      amount: map['amount'].toDouble(),
      imagePath: map['image_path'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Expense copyWith({int? id, String? date, String? description, String? category, double? amount, String? imagePath, String? notes}) {
    return Expense(id: id ?? this.id, date: date ?? this.date, description: description ?? this.description, category: category ?? this.category, amount: amount ?? this.amount, imagePath: imagePath ?? this.imagePath, notes: notes ?? this.notes, createdAt: createdAt);
  }
}

class ExpenseCategory {
  final String nameAr;
  final String nameFr;
  final String icon;
  final int colorValue;

  const ExpenseCategory({required this.nameAr, required this.nameFr, required this.icon, required this.colorValue});

  static const List<ExpenseCategory> all = [
    ExpenseCategory(nameAr: 'دروغري/ مواد البناء', nameFr: 'Matériaux/Droguerie', icon: '🧱', colorValue: 0xFF1A3A5C),
    ExpenseCategory(nameAr: 'المرتوب', nameFr: 'Salaires', icon: '💼', colorValue: 0xFFD35400),
    ExpenseCategory(nameAr: 'جبس', nameFr: 'Plâtre', icon: '🔲', colorValue: 0xFF2980B9),
    ExpenseCategory(nameAr: 'معلم  البناء', nameFr: 'Maçon', icon: '👷', colorValue: 0xFF27AE60),
    ExpenseCategory(nameAr: 'زليج السطح', nameFr: 'Carrelage Toit', icon: '🔷', colorValue: 0xFF16A085),
    ExpenseCategory(nameAr: 'كهرباء/ماء', nameFr: 'Électricité/Eau', icon: '⚡', colorValue: 0xFFF39C12),
    ExpenseCategory(nameAr: 'حدادة', nameFr: 'Ferronnerie', icon: '⚙️', colorValue: 0xFFE74C3C),
    ExpenseCategory(nameAr: 'خشب', nameFr: 'Bois/Menuiserie', icon: '🪵', colorValue: 0xFF8E44AD),
    ExpenseCategory(nameAr: 'رخص', nameFr: 'Permis/Licences', icon: '📄', colorValue: 0xFF7F8C8D),
    ExpenseCategory(nameAr: 'أخرى', nameFr: 'Autres', icon: '📦', colorValue: 0xFF95A5A6),
  ];

  static ExpenseCategory? findByName(String name) {
    try { return all.firstWhere((c) => c.nameAr == name || c.nameFr == name); } catch (_) { return null; }
  }
}

// ✅ DONNÉES EXACTES extraites du fichier Excel ENNIFI 2025
// Total vérifié: 213,188 DH | 63 opérations
final List<Map<String, dynamic>> initialExpenses = [
  {'date': '2025-07-07', 'desc': 'تجديد رخصة', 'cat': 'رخص', 'amt': 1200.0},
  {'date': '2025-07-15', 'desc': 'تسبيق دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 25000.0},
  {'date': '2025-07-16', 'desc': 'رملة + كياس', 'cat': 'دروغري/ مواد البناء', 'amt': 5800.0},
  {'date': '2025-07-28', 'desc': 'دفعة 1 للمعلم', 'cat': 'معلم  البناء', 'amt': 5000.0},
  {'date': '2025-07-31', 'desc': 'حديد', 'cat': 'حدادة', 'amt': 880.0},
  {'date': '2025-07-31', 'desc': 'تسبيق سدور', 'cat': 'حدادة', 'amt': 300.0},
  {'date': '2025-07-31', 'desc': 'دفعة للمعلم لحديد', 'cat': 'حدادة', 'amt': 300.0},
  {'date': '2025-08-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2025-08-04', 'desc': 'دفعة 2 للمعلم', 'cat': 'معلم  البناء', 'amt': 5000.0},
  {'date': '2025-08-11', 'desc': 'دفعة 3 للمعلم', 'cat': 'معلم  البناء', 'amt': 5500.0},
  {'date': '2025-08-18', 'desc': 'دفعة 4 للمعلم', 'cat': 'معلم  البناء', 'amt': 3650.0},
  {'date': '2025-09-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2025-09-08', 'desc': 'حداد', 'cat': 'حدادة', 'amt': 800.0},
  {'date': '2025-09-09', 'desc': 'حديد', 'cat': 'حدادة', 'amt': 2200.0},
  {'date': '2025-09-17', 'desc': 'كود بواتي(الماء) 41 وحدة', 'cat': 'كهرباء/ماء', 'amt': 1500.0},
  {'date': '2025-09-17', 'desc': 'تسبيق حداد', 'cat': 'حدادة', 'amt': 500.0},
  {'date': '2025-09-18', 'desc': 'كونكورد', 'cat': 'كهرباء/ماء', 'amt': 2900.0},
  {'date': '2025-09-22', 'desc': 'تريسيان', 'cat': 'كهرباء/ماء', 'amt': 9500.0},
  {'date': '2025-09-29', 'desc': 'تسبيق حداد', 'cat': 'حدادة', 'amt': 200.0},
  {'date': '2025-10-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2025-10-16', 'desc': 'رملة', 'cat': 'دروغري/ مواد البناء', 'amt': 4300.0},
  {'date': '2025-10-17', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 2400.0},
  {'date': '2025-10-18', 'desc': 'دفعة 1 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 2500.0},
  {'date': '2025-10-18', 'desc': 'خشب 3000FC', 'cat': 'خشب', 'amt': 3000.0},
  {'date': '2025-10-22', 'desc': 'حداد', 'cat': 'حدادة', 'amt': 400.0},
  {'date': '2025-10-22', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 1654.0},
  {'date': '2025-10-25', 'desc': 'حديد', 'cat': 'حدادة', 'amt': 4100.0},
  {'date': '2025-10-25', 'desc': 'حداد1', 'cat': 'حدادة', 'amt': 300.0},
  {'date': '2025-10-27', 'desc': 'دفعة 2 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 7000.0},
  {'date': '2025-10-27', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 1654.0},
  {'date': '2025-10-31', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 2000.0},
  {'date': '2025-11-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2025-11-03', 'desc': 'دفعة 3 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 9000.0},
  {'date': '2025-11-05', 'desc': 'حداد2', 'cat': 'حدادة', 'amt': 500.0},
  {'date': '2025-11-07', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 1600.0},
  {'date': '2025-11-08', 'desc': 'رملة', 'cat': 'دروغري/ مواد البناء', 'amt': 2800.0},
  {'date': '2025-11-10', 'desc': 'دفعة 4 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 4000.0},
  {'date': '2025-11-16', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 2500.0},
  {'date': '2025-11-17', 'desc': 'دفعة 5 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 4000.0},
  {'date': '2025-11-17', 'desc': 'دفعة 6 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 5000.0},
  {'date': '2025-11-18', 'desc': 'حداد', 'cat': 'حدادة', 'amt': 200.0},
  {'date': '2025-11-26', 'desc': 'تسبيق الزلايجي السطح', 'cat': 'زليج السطح', 'amt': 1500.0},
  {'date': '2025-11-26', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 2750.0},
  {'date': '2025-11-26', 'desc': 'زليج السطح1', 'cat': 'زليج السطح', 'amt': 9700.0},
  {'date': '2025-11-29', 'desc': 'سيمة', 'cat': 'دروغري/ مواد البناء', 'amt': 500.0},
  {'date': '2025-11-29', 'desc': 'زليج السطح2', 'cat': 'زليج السطح', 'amt': 400.0},
  {'date': '2025-11-29', 'desc': 'حداد', 'cat': 'حدادة', 'amt': 1000.0},
  {'date': '2025-11-30', 'desc': 'دفعة الزلايجي السطح', 'cat': 'زليج السطح', 'amt': 2000.0},
  {'date': '2025-12-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2025-12-04', 'desc': 'دفعة الزلايجي السطح', 'cat': 'زليج السطح', 'amt': 3500.0},
  {'date': '2025-12-31', 'desc': 'كابل كهربائي للجبس', 'cat': 'جبس', 'amt': 200.0},
  {'date': '2026-01-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2026-01-05', 'desc': 'جباس', 'cat': 'جبس', 'amt': 3000.0},
  {'date': '2026-01-10', 'desc': 'كابل كهربائي للجبس', 'cat': 'جبس', 'amt': 400.0},
  {'date': '2026-01-10', 'desc': 'حداد', 'cat': 'حدادة', 'amt': 1600.0},
  {'date': '2026-01-12', 'desc': 'جباس', 'cat': 'جبس', 'amt': 5000.0},
  {'date': '2026-01-19', 'desc': 'جباس', 'cat': 'جبس', 'amt': 5000.0},
  {'date': '2026-01-25', 'desc': 'جباس', 'cat': 'جبس', 'amt': 5000.0},
  {'date': '2026-02-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
  {'date': '2026-02-02', 'desc': 'جباس', 'cat': 'جبس', 'amt': 4000.0},
  {'date': '2026-02-09', 'desc': 'جباس', 'cat': 'جبس', 'amt': 3500.0},
  {'date': '2026-02-23', 'desc': 'دفعة 7 للمعلم (المرتوب)', 'cat': 'المرتوب', 'amt': 3000.0},
  {'date': '2026-03-01', 'desc': 'دفعة دروغري', 'cat': 'دروغري/ مواد البناء', 'amt': 4000.0},
];
