import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/database_helper.dart';
import '../models/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _budget = 400000;
  bool _hasPassword = false;
  String _appName = 'ENNIFI 2025';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = DatabaseHelper.instance;
    final budget = await db.getBudget();
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString('password_hash') ?? '';
    final name = await db.getSetting('app_name') ?? 'ENNIFI 2025';
    setState(() {
      _budget = budget;
      _hasPassword = hash.isNotEmpty;
      _appName = name;
    });
  }

  Future<void> _editBudget(bool isAr) async {
    final ctrl = TextEditingController(text: _budget.toStringAsFixed(0));
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تعديل الميزانية' : 'Modifier le budget'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isAr ? 'الميزانية الإجمالية (درهم)' : 'Budget total (DH)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text), child: Text(isAr ? 'حفظ' : 'Enregistrer')),
        ],
      ),
    );
    if (result != null) {
      final val = double.tryParse(result);
      if (val != null) {
        await DatabaseHelper.instance.setBudget(val);
        setState(() => _budget = val);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم تحديث الميزانية' : 'Budget mis à jour')));
      }
    }
  }

  Future<void> _changePassword(bool isAr) async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'تغيير الرمز السري' : 'Changer le code PIN'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          decoration: InputDecoration(
            labelText: isAr ? 'رمز PIN جديد (6 أرقام)' : 'Nouveau code PIN (6 chiffres)',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isAr ? 'إلغاء' : 'Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.length == 6) {
                final prefs = await SharedPreferences.getInstance();
                final bytes = utf8.encode(ctrl.text + 'ennifi_salt_2025');
                await prefs.setString('password_hash', sha256.convert(bytes).toString());
                setState(() => _hasPassword = true);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'تم تغيير الرمز بنجاح' : 'Code modifié avec succès')));
                }
              }
            },
            child: Text(isAr ? 'حفظ' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _removePassword(bool isAr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'إزالة الرمز السري' : 'Supprimer le code'),
        content: Text(isAr ? 'هل تريد إزالة حماية كلمة المرور؟' : 'Voulez-vous supprimer la protection?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isAr ? 'لا' : 'Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(isAr ? 'نعم' : 'Oui', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('password_hash');
      setState(() => _hasPassword = false);
    }
  }

  Future<void> _toggleLanguage(bool isAr, AppStateProvider? state) async {
    state?.onLocaleChanged(isAr ? const Locale('fr') : const Locale('ar'));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isAr = state?.isArabic ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: Text(isAr ? 'الإعدادات' : 'Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // معلومات التطبيق
          _SettingsSection(
            title: isAr ? 'التطبيق' : 'Application',
            children: [
              _SettingsTile(
                icon: Icons.home_work_rounded,
                title: isAr ? 'اسم المشروع' : 'Nom du projet',
                subtitle: _appName,
                onTap: null,
              ),
              _SettingsTile(
                icon: Icons.account_balance_wallet_rounded,
                title: isAr ? 'الميزانية الإجمالية' : 'Budget total',
                subtitle: '${_budget.toStringAsFixed(0)} ${isAr ? 'درهم' : 'DH'}',
                onTap: () => _editBudget(isAr),
                trailing: const Icon(Icons.edit_rounded, color: Color(0xFF1A3A5C), size: 18),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // اللغة
          _SettingsSection(
            title: isAr ? 'اللغة' : 'Langue',
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: isAr ? 'اللغة الحالية' : 'Langue actuelle',
                subtitle: isAr ? 'العربية' : 'Français',
                onTap: () => _toggleLanguage(isAr, state),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1A3A5C).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(isAr ? 'FR ←' : '← ع', style: const TextStyle(color: Color(0xFF1A3A5C), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // الأمان
          _SettingsSection(
            title: isAr ? 'الأمان' : 'Sécurité',
            children: [
              _SettingsTile(
                icon: Icons.lock_rounded,
                title: isAr ? 'الرمز السري (PIN)' : 'Code PIN',
                subtitle: _hasPassword ? (isAr ? 'مفعّل ✓' : 'Activé ✓') : (isAr ? 'غير مفعّل' : 'Désactivé'),
                onTap: () => _changePassword(isAr),
                trailing: Icon(Icons.chevron_right, color: _hasPassword ? Colors.green : Colors.grey),
              ),
              if (_hasPassword)
                _SettingsTile(
                  icon: Icons.lock_open_rounded,
                  title: isAr ? 'إزالة الرمز السري' : 'Supprimer le code',
                  subtitle: isAr ? 'إلغاء حماية التطبيق' : 'Désactiver la protection',
                  onTap: () => _removePassword(isAr),
                  titleColor: Colors.red,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // معلومات
          _SettingsSection(
            title: isAr ? 'معلومات' : 'Informations',
            children: [
              _SettingsTile(icon: Icons.info_rounded, title: isAr ? 'الإصدار' : 'Version', subtitle: '1.0.0', onTap: null),
              _SettingsTile(icon: Icons.person_rounded, title: isAr ? 'المطور' : 'Développeur', subtitle: 'ENNIFI', onTap: null),
            ],
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 0.5)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))]),
          child: Column(
            children: List.generate(children.length, (i) => Column(
              children: [
                children[i],
                if (i < children.length - 1) const Divider(height: 1, indent: 56),
              ],
            )),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: const Color(0xFF1A3A5C).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: titleColor ?? const Color(0xFF1A3A5C), size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: titleColor)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
