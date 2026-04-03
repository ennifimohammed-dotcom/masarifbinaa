import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  double _total = 0, _budget = 400000;
  Map<String, double> _catTotals = {};
  Map<String, double> _monthlyTotals = {};
  List<Expense> _recent = [];
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final db = DatabaseHelper.instance;
    final results = await Future.wait([
      db.getTotalAmount(), db.getBudget(),
      db.getCategoryTotals(), db.getMonthlyTotals(), db.getAllExpenses(),
    ]);
    setState(() {
      _total = results[0] as double;
      _budget = results[1] as double;
      _catTotals = results[2] as Map<String, double>;
      _monthlyTotals = results[3] as Map<String, double>;
      _recent = (results[4] as List<Expense>).take(5).toList();
    });
    _animCtrl.forward(from: 0);
  }

  static const _colors = [
    Color(0xFF1A3A5C), Color(0xFFD35400), Color(0xFF2980B9),
    Color(0xFF27AE60), Color(0xFF16A085), Color(0xFFF39C12),
    Color(0xFFE74C3C), Color(0xFF8E44AD), Color(0xFF7F8C8D),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final remaining = _budget - _total;
    final progress = (_total / _budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: RefreshIndicator(
        color: const Color(0xFF27AE60),
        onRefresh: _loadData,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(slivers: [
            // ── Header vert style Wallet ──
            SliverToBoxAdapter(child: _buildHeader(isAr, progress, remaining)),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [
                const SizedBox(height: 16),
                // Cartes catégories style Wallet
                _buildCategoryCards(isAr),
                const SizedBox(height: 20),
                // Graphique camembert + légende
                _buildPieSection(isAr),
                const SizedBox(height: 20),
                // Graphique barres mensuel
                _buildMonthlySection(isAr),
                const SizedBox(height: 20),
                // Dernières transactions
                _buildRecentSection(isAr),
                const SizedBox(height: 90),
              ]),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAr, double progress, double remaining) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1E5C3A), Color(0xFF27AE60)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(children: [
            // Top bar
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAr ? 'مرحباً،' : 'Bonjour,',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Text('ENNIFI 2025',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    const Icon(Icons.home_work_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(isAr ? 'البناء' : 'Chantier',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),
              ]),
            ]),
            const SizedBox(height: 24),
            // Montant total
            Text(isAr ? 'إجمالي المصاريف' : 'Total des dépenses',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(formatAmount(_total, suffix: isAr ? 'درهم' : 'DH'),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
                letterSpacing: 0.5)),
            const SizedBox(height: 20),
            // Barre budget
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isAr ? 'مصروف' : 'Dépensé',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(formatAmount(_total, withSuffix: false),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(isAr ? 'الميزانية' : 'Budget',
                      style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(formatAmount(_budget, withSuffix: false),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.9 ? Colors.redAccent : Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                    remaining >= 0
                      ? '${isAr ? 'متبقي: ' : 'Reste: '}${formatAmount(remaining, withSuffix: false)}'
                      : '${isAr ? 'تجاوز: ' : 'Dépassé: '}${formatAmount(remaining.abs(), withSuffix: false)}',
                    style: TextStyle(
                      color: remaining >= 0 ? Colors.white : Colors.redAccent,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCategoryCards(bool isAr) {
    final sorted = _catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isEmpty) return const SizedBox();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(title: isAr ? 'قائمة الفئات' : 'Liste des catégories',
        action: isAr ? 'عرض الكل' : 'Tout voir'),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          // Total ligne header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FFFE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF27AE60).withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF27AE60), size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAr ? 'الإجمالي الكلي' : 'Total général',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatAmount(_total, suffix: isAr ? 'درهم' : 'DH'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
                child: Text('${sorted.length} ${isAr ? 'فئة' : 'cat.'}',
                  style: const TextStyle(color: Color(0xFF27AE60), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // Lignes catégories
          ...List.generate(sorted.length, (i) {
            final e = sorted[i];
            final cat = ExpenseCategory.findByName(e.key);
            final color = _colors[i % _colors.length];
            final pct = _total > 0 ? e.value / _total * 100 : 0.0;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(cat?.icon ?? '📦',
                      style: const TextStyle(fontSize: 20)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    ClipRRect(borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4)),
                  ])),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(formatAmount(e.value, withSuffix: false),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                    Text('${pct.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ]),
              ),
              if (i < sorted.length - 1)
                const Divider(height: 1, indent: 68, color: Color(0xFFF5F5F5)),
            ]);
          }),
        ]),
      ),
    ]);
  }

  Widget _buildPieSection(bool isAr) {
    if (_catTotals.isEmpty) return const SizedBox();
    final sorted = _catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(title: isAr ? 'الإنفاق حسب الفئة' : 'Dépenses par catégorie'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          SizedBox(height: 200,
            child: PieChart(PieChartData(
              sections: List.generate(sorted.length, (i) => PieChartSectionData(
                value: sorted[i].value,
                color: _colors[i % _colors.length],
                radius: 65,
                title: '${(sorted[i].value / _total * 100).toStringAsFixed(0)}%',
                titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              )),
              centerSpaceRadius: 45,
              sectionsSpace: 3,
            )),
          ),
          const SizedBox(height: 16),
          // Légende 2 colonnes
          Wrap(spacing: 16, runSpacing: 10,
            children: List.generate(sorted.length, (i) => SizedBox(
              width: (MediaQuery.of(context).size.width - 72) / 2,
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(
                  color: _colors[i % _colors.length], borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 6),
                Expanded(child: Text(sorted[i].key,
                  style: const TextStyle(fontSize: 11, color: Colors.black87), overflow: TextOverflow.ellipsis)),
              ]),
            )),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildMonthlySection(bool isAr) {
    if (_monthlyTotals.isEmpty) return const SizedBox();
    final months = _monthlyTotals.keys.toList()..sort();
    final values = months.map((m) => _monthlyTotals[m]!).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final labelsAr = {'01':'يناير','02':'فبراير','03':'مارس','04':'أبريل','05':'ماي','06':'يونيو','07':'يوليوز','08':'غشت','09':'شتنبر','10':'أكتوبر','11':'نونبر','12':'دجنبر'};
    final labelsFr = {'01':'Jan','02':'Fév','03':'Mar','04':'Avr','05':'Mai','06':'Jun','07':'Jul','08':'Aoû','09':'Sep','10':'Oct','11':'Nov','12':'Déc'};

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(title: isAr ? 'الإنفاق الشهري' : 'Dépenses mensuelles'),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: SizedBox(height: 180,
          child: BarChart(BarChartData(
            maxY: maxVal * 1.25,
            gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= months.length) return const SizedBox();
                  final mo = months[idx].substring(5, 7);
                  final lbl = isAr ? (labelsAr[mo] ?? mo) : (labelsFr[mo] ?? mo);
                  return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(lbl.substring(0, 3), style: const TextStyle(fontSize: 9, color: Colors.grey)));
                },
              )),
            ),
            barGroups: List.generate(months.length, (i) {
              final isMax = values[i] == maxVal;
              return BarChartGroupData(x: i, barRods: [BarChartRodData(
                toY: values[i],
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: isMax
                    ? [const Color(0xFF27AE60), const Color(0xFF2ECC71)]
                    : [const Color(0xFF1A3A5C).withOpacity(0.7), const Color(0xFF2E6BA8)]),
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )]);
            }),
            barTouchData: BarTouchData(touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                formatAmount(rod.toY, withSuffix: false),
                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            )),
          )),
        ),
      ),
    ]);
  }

  Widget _buildRecentSection(bool isAr) {
    if (_recent.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(title: isAr ? 'آخر المعاملات' : 'Dernières transactions',
        action: isAr ? 'عرض الكل' : 'Tout voir'),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(children: List.generate(_recent.length, (i) {
          final e = _recent[i];
          final cat = ExpenseCategory.findByName(e.category);
          final color = _colors[ExpenseCategory.all.indexWhere((c) => c.nameAr == e.category) % _colors.length];
          return Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(cat?.icon ?? '📦', style: const TextStyle(fontSize: 22)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Text(e.category, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))),
                    const SizedBox(width: 6),
                    Text(e.date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),
                ])),
                Text('-${formatAmount(e.amount, withSuffix: false)}',
                  style: const TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ),
            if (i < _recent.length - 1)
              const Divider(height: 1, indent: 72, color: Color(0xFFF5F5F5)),
          ]);
        })),
      ),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
      if (action != null)
        Text(action!, style: const TextStyle(fontSize: 12, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
    ]);
  }
}
