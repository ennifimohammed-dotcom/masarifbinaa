import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/database_helper.dart';
import '../models/expense.dart';
import '../models/app_state.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descCtrl;
  late TextEditingController _amtCtrl;
  late TextEditingController _notesCtrl;
  String _selectedCat = 'دروغري/ مواد البناء';
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  String? _imagePath;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _amtCtrl = TextEditingController(text: e?.amount.toStringAsFixed(0) ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    if (e != null) {
      _selectedCat = e.category;
      _selectedDate = e.date;
      _imagePath = e.imagePath;
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_selectedDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked.toIso8601String().substring(0, 10));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final expense = Expense(
      id: widget.expense?.id,
      date: _selectedDate,
      description: _descCtrl.text.trim(),
      category: _selectedCat,
      amount: double.parse(_amtCtrl.text.trim()),
      imagePath: _imagePath,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final db = DatabaseHelper.instance;
    if (widget.expense == null) {
      await db.insertExpense(expense);
    } else {
      await db.updateExpense(expense);
    }

    // فحص الميزانية
    final total = await db.getTotalAmount();
    final budget = await db.getBudget();
    if (total > budget * 0.9 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(total > budget ? '⚠️ تجاوزت الميزانية!' : '⚠️ اقتربت من حد الميزانية (90%)'),
        backgroundColor: total > budget ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 4),
      ));
    }

    setState(() => _loading = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;
    final isEdit = widget.expense != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(isEdit ? (isAr ? 'تعديل النفقة' : 'Modifier la dépense') : (isAr ? 'إضافة نفقة' : 'Ajouter une dépense')),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(isAr ? 'حفظ' : 'Enregistrer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FormCard(children: [
              // التاريخ
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF1A3A5C)),
                title: Text(isAr ? 'التاريخ' : 'Date', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                subtitle: Text(_selectedDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const Divider(height: 1),

              // الوصف
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'الوصف' : 'Description',
                  prefixIcon: const Icon(Icons.description_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v?.isEmpty ?? true ? (isAr ? 'مطلوب' : 'Requis') : null,
              ),
              const SizedBox(height: 12),

              // المبلغ
              TextFormField(
                controller: _amtCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'المبلغ (درهم)' : 'Montant (DH)',
                  prefixIcon: const Icon(Icons.payments_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: isAr ? 'درهم' : 'DH',
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return isAr ? 'مطلوب' : 'Requis';
                  if (double.tryParse(v!) == null) return isAr ? 'رقم غير صحيح' : 'Nombre invalide';
                  return null;
                },
              ),
            ]),

            const SizedBox(height: 16),

            // الفئة
            _FormCard(children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(isAr ? 'الصنف' : 'Catégorie', style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.all.map((cat) {
                  final selected = _selectedCat == cat.nameAr;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = cat.nameAr),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Color(cat.colorValue) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? Color(cat.colorValue) : Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.icon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            isAr ? cat.nameAr : cat.nameFr,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),

            const SizedBox(height: 16),

            // ملاحظات وصورة
            _FormCard(children: [
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optionnel)',
                  prefixIcon: const Icon(Icons.note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_rounded),
                label: Text(isAr ? 'إرفاق صورة الفاتورة' : 'Joindre une photo facture'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A3A5C),
                  side: const BorderSide(color: Color(0xFF1A3A5C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_imagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : Text(
                      isEdit ? (isAr ? 'تحديث النفقة' : 'Mettre à jour') : (isAr ? 'إضافة النفقة' : 'Ajouter la dépense'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
