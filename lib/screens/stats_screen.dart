import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';
import '../utils/formatters.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, double> _catTotals = {};
  double _total = 0;
  double _budget = 400000;
  bool _exporting = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final cats = await db.getCategoryTotals();
    final total = await db.getTotalAmount();
    final budget = await db.getBudget();
    setState(() { _catTotals = cats; _total = total; _budget = budget; });
  }

  Future<void> _exportPDF() async {
    setState(() => _exporting = true);
    final db = DatabaseHelper.instance;
    final all = await db.getAllExpenses();

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('ENNIFI 2025 - تقرير مصاريف البناء',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
        pw.SizedBox(height: 8),
        pw.Text('تاريخ التقرير: ${DateTime.now().toIso8601String().substring(0, 10)}'),
        pw.SizedBox(height: 4),
        pw.Text('الإجمالي: ${formatAmount(_total, suffix: 'درهم')}'),
        pw.Text('الميزانية: ${formatAmount(_budget, suffix: 'درهم')}'),
        pw.Text('المتبقي: ${formatAmount((_budget - _total).abs(), suffix: 'درهم')}'),
        pw.SizedBox(height: 20),
        pw.Text('التفصيل حسب الفئة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['الفئة', 'المبلغ (درهم)', 'النسبة'],
          data: _catTotals.entries.map((e) => [
            e.key,
            formatAmount(e.value, withSuffix: false),
            '${(e.value / _total * 100).toStringAsFixed(1)}%',
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        ),
        pw.SizedBox(height: 20),
        pw.Text('قائمة النفقات الكاملة:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['التاريخ', 'الوصف', 'الصنف', 'المبلغ (درهم)'],
          data: all.map((e) => [
            e.date, e.description, e.category,
            formatAmount(e.amount, withSuffix: false),
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ));

    setState(() => _exporting = false);
    if (mounted) await Printing.sharePdf(bytes: await pdf.save(), filename: 'ennifi_rapport.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final remaining = _budget - _total;
    final colors = [const Color(0xFF1A3A5C), const Color(0xFFD35400), const Color(0xFF2980B9), const Color(0xFF27AE60), const Color(0xFF16A085), const Color(0xFFF39C12), const Color(0xFFE74C3C), const Color(0xFF8E44AD), const Color(0xFF7F8C8D)];
    final sorted = _catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isAr ? 'التقارير والإحصاء' : 'Rapports & Statistiques'),
        actions: [
          IconButton(
            onPressed: _exporting ? null : _exportPDF,
            icon: _exporting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.picture_as_pdf_rounded),
            tooltip: isAr ? 'تصدير PDF' : 'Exporter PDF',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // 4 cartes métriques
          Row(children: [
            _StatCard(label: isAr ? 'إجمالي المصاريف' : 'Total dépenses',
              value: formatAmount(_total, withSuffix: false),
              suffix: isAr ? 'درهم' : 'DH', color: const Color(0xFF1A3A5C), icon: '💰'),
            const SizedBox(width: 10),
            _StatCard(label: isAr ? 'المتبقي' : 'Restant',
              value: formatAmount(remaining.abs(), withSuffix: false),
              suffix: isAr ? 'درهم' : 'DH',
              color: remaining >= 0 ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
              icon: remaining >= 0 ? '✅' : '⚠️'),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _StatCard(label: isAr ? 'الميزانية' : 'Budget',
              value: formatAmount(_budget, withSuffix: false),
              suffix: isAr ? 'درهم' : 'DH', color: const Color(0xFF8E44AD), icon: '🎯'),
            const SizedBox(width: 10),
            _StatCard(label: isAr ? 'نسبة الاستهلاك' : 'Taux',
              value: '${(_total / _budget * 100).toStringAsFixed(1)}%',
              suffix: '', color: const Color(0xFFF39C12), icon: '📊'),
          ]),

          const SizedBox(height: 20),

          // Barre de progression budget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? 'تقدم الميزانية' : 'Avancement budget',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_total / _budget).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _total > _budget ? Colors.red : const Color(0xFF1A3A5C)),
                  minHeight: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${(_total / _budget * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
                Text(formatAmount(_budget, suffix: isAr ? 'درهم' : 'DH'),
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Tableau détaillé avec format uniforme
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(color: Color(0xFF1A3A5C),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(isAr ? 'الفئة' : 'Catégorie',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(flex: 2, child: Text(isAr ? 'المبلغ (درهم)' : 'Montant (DH)',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                  Expanded(child: Text('%', textAlign: TextAlign.end,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                ]),
              ),
              ...List.generate(sorted.length, (i) {
                final e = sorted[i];
                final pct = _total > 0 ? e.value / _total : 0.0;
                final cat = ExpenseCategory.findByName(e.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: i.isEven ? Colors.white : const Color(0xFFF8F9FA),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(flex: 3, child: Row(children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(
                          color: colors[i % colors.length], borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 6),
                        Text(cat?.icon ?? '📦', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(child: Text(e.key,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ])),
                      Expanded(flex: 2, child: Text(formatAmount(e.value, withSuffix: false),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C)))),
                      Expanded(child: Text('${(pct * 100).toStringAsFixed(1)}%',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 12, color: colors[i % colors.length], fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(colors[i % colors.length]),
                        minHeight: 5)),
                  ]),
                );
              }),
              // Ligne total
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(isAr ? 'الإجمالي' : 'TOTAL',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A3A5C)))),
                  Expanded(flex: 2, child: Text(formatAmount(_total, withSuffix: false),
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A3A5C)))),
                  Expanded(child: Text('100%', textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1A3A5C)))),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _exporting ? null : _exportPDF,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            label: Text(isAr ? 'تصدير التقرير PDF' : 'Exporter rapport PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC0392B), foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, suffix, icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.suffix, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        if (suffix.isNotEmpty) Text(suffix, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    ));
  }
}
