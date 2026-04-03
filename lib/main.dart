import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/home_screen.dart';
import 'models/database_helper.dart';
import 'models/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await DatabaseHelper.instance.database;
  runApp(const ENNIFIApp());
}

class ENNIFIApp extends StatefulWidget {
  const ENNIFIApp({super.key});

  @override
  State<ENNIFIApp> createState() => _ENNIFIAppState();
}

class _ENNIFIAppState extends State<ENNIFIApp> {
  Locale _locale = const Locale('ar');

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      locale: _locale,
      onLocaleChanged: setLocale,
      child: MaterialApp(
        title: 'ENNIFI - مصاريف البناء',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        supportedLocales: const [Locale('ar'), Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A3A5C),
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A3A5C),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A3A5C),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/lock': (_) => const LockScreen(),
          '/home': (_) => const HomeScreen(),
        },
      ),
    );
  }
}
