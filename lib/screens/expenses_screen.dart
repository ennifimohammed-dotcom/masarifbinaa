import 'package:flutter/material.dart';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';
import '../utils/formatters.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  List<Expense> _filtered = [];
  String _selectedCat = 'الكل';
  String _search = '';
  final _searchCtrl = TextEditingController();

  static const _colors = [
    Color(0xFF1A3A5C), Color(0xFFD35400), Color(0xFF2980B9),
    Color(0xFF27AE60), Color(0xFF16A085), Color(0xFFF39C12),
    Color(0xFFE74C3C), Color(0xFF8E44AD), Color(0xFF7F8C8D),
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getAllExpenses();
    setState(() { _expenses = all; _applyFilter(); });
  }

  void _applyFilter() {
    _filtered = _expenses.where((e) {
      final catMatch = _selectedCat == 'الكل' || e.category == _selectedCat;
      final searchMatch = _search.isEmpty ||
        e.description.toLowerCase().contains(_search.toLowerCase()) ||
        e.category.toLowerCase().contains(_search.toLowerCase());
      return catMatch && searchMatch;
    }).toList();
  }

  Future<void> _delete(Expense e) async {
    final confirm = await showDialog<bool>(context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: Text('حذف "${e.description}"؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) { await DatabaseHelper.instance.deleteExpense(e.id!); _load(); }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final categories = ['الكل', ...ExpenseCategory.all.map((c) => c.nameAr)];
    final filteredTotal = _filtered.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Column(children: [
        // Header vert
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1E5C3A), Color(0xFF27AE60)]),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(isAr ? 'قائمة النفقات' : 'Liste des dépenses',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('${_filtered.length} ${isAr ? 'عملية' : 'op.'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              // Total filtré
              Text(formatAmount(filteredTotal, suffix: isAr ? 'درهم' : 'DH'),
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              // Barre de recherche
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() { _search = v; _applyFilter(); }),
                  decoration: InputDecoration(
                    hintText: isAr ? 'بحث في النفقات...' : 'Rechercher...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                    suffixIcon: _search.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear_rounded, color: Colors.grey, size: 18),
                          onPressed: () => setState(() { _search = ''; _searchCtrl.clear(); _applyFilter(); }))
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          )),
        ),

        // Filtres catégories
        SizedBox(height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = cat == _selectedCat;
              final catObj = cat == 'الكل' ? null : ExpenseCategory.findByName(cat);
              return GestureDetector(
                onTap: () => setState(() { _selectedCat = cat; _applyFilter(); }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF27AE60) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected ? [BoxShadow(color: const Color(0xFF27AE60).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
                    border: Border.all(color: selected ? const Color(0xFF27AE60) : Colors.grey.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (catObj != null) ...[Text(catObj.icon, style: const TextStyle(fontSize: 12)), const SizedBox(width: 4)],
                    Text(cat == 'الكل' ? (isAr ? 'الكل' : 'Tout') : (catObj?.nameAr ?? cat),
                      style: TextStyle(fontSize: 12, color: selected ? Colors.white : Colors.black87,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                  ]),
                ),
              );
            },
          ),
        ),

        // Liste
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF27AE60),
            onRefresh: _load,
            child: _filtered.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📋', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(isAr ? 'لا توجد نفقات' : 'Aucune dépense',
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _ExpenseTile(
                    expense: _filtered[i],
                    isAr: isAr,
                    colors: _colors,
                    onDelete: () => _delete(_filtered[i]),
                    onEdit: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: _filtered[i])));
                      _load();
                    },
                  ),
                ),
          ),
        ),
      ]),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final bool isAr;
  final List<Color> colors;
  final VoidCallback onDelete, onEdit;

  const _ExpenseTile({required this.expense, required this.isAr, required this.colors, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final catIndex = ExpenseCategory.all.indexWhere((c) => c.nameAr == expense.category);
    final color = catIndex >= 0 ? colors[catIndex % colors.length] : const Color(0xFF888888);
    final cat = ExpenseCategory.findByName(expense.category);
    final icon = cat?.icon ?? '📦';

    return Dismissible(
      key: Key('exp_${expense.id}'),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { onDelete(); return false; },
      child: GestureDetector(
        onLongPress: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            Container(width: 46, height: 46,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text(icon, style: const TextStyle(fontSize: 22)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text(expense.category, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600))),
                const SizedBox(width: 6),
                Text(expense.date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('-${formatAmount(expense.amount, withSuffix: false)}',
                style: const TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.bold, fontSize: 15)),
              Text(isAr ? 'درهم' : 'DH', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ]),
        ),
      ),
    );
  }
}
