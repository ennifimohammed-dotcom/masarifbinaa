import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  String _error = '';
  bool _isSetup = false;
  String _confirmPin = '';
  bool _setupStep2 = false;

  @override
  void initState() {
    super.initState();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final hash = prefs.getString('password_hash') ?? '';
    setState(() => _isSetup = hash.isEmpty);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'ennifi_salt_2025');
    return sha256.convert(bytes).toString();
  }

  void _onKeyPress(String key) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += key;
      _error = '';
    });
    if (_pin.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), _verify);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    if (_isSetup) {
      if (!_setupStep2) {
        setState(() {
          _confirmPin = _pin;
          _pin = '';
          _setupStep2 = true;
        });
      } else {
        if (_pin == _confirmPin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('password_hash', _hashPin(_pin));
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        } else {
          setState(() {
            _pin = '';
            _confirmPin = '';
            _setupStep2 = false;
            _error = 'الرمز غير متطابق — Code non concordant';
          });
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('password_hash') ?? '';
      if (_hashPin(_pin) == stored) {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _pin = '';
          _error = 'رمز خاطئ — Code incorrect';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏗️', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            Text(
              _isSetup
                  ? (_setupStep2 ? 'تأكيد الرمز\nConfirmez le code' : 'إنشاء رمز PIN\nCréer un code PIN')
                  : 'أدخل الرمز السري\nEntrez votre code',
              style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? Colors.white : Colors.white24,
                  border: Border.all(color: Colors.white54, width: 1.5),
                ),
              )),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(_error, style: const TextStyle(color: Colors.redAccent, fontSize: 14), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 50),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];
    return Column(
      children: keys.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80, height: 70);
            return GestureDetector(
              onTap: k == '⌫' ? _onDelete : () => _onKeyPress(k),
              child: Container(
                width: 80,
                height: 70,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    k,
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}
