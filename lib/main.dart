import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/providers/theme_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ZimMarketApp(),
    ),
  );
}

class ZimMarketApp extends StatelessWidget {
  const ZimMarketApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Check if user is already logged in
    final appState = Provider.of<AppState>(context, listen: false);
    appState.checkCurrentUser();
    
    return MaterialApp(
      title: 'ZimMarket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const LoginScreen(),
    );
  }
}