import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final hasPassword = prefs.getString('password_hash')?.isNotEmpty ?? false;
    Navigator.pushReplacementNamed(context, hasPassword ? '/lock' : '/home');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1E5C3A), Color(0xFF27AE60), Color(0xFF2ECC71)]),
        ),
        child: Center(
          child: FadeTransition(opacity: _fade,
            child: ScaleTransition(scale: _scale,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Center(child: Text('🏗️', style: TextStyle(fontSize: 56)))),
                const SizedBox(height: 28),
                const Text('ENNIFI', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 6)),
                const SizedBox(height: 8),
                const Text('متابعة مصاريف البناء', style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 4),
                const Text('Suivi des Dépenses', style: TextStyle(fontSize: 13, color: Colors.white54)),
                const SizedBox(height: 60),
                SizedBox(width: 36, height: 36,
                  child: CircularProgressIndicator(strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)))),
              ]),
            )),
        ),
      ),
    );
  }
}
