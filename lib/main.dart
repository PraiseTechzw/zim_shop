import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/firebase_config.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/providers/theme_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/screen/buyer_main_screen.dart';
import 'package:zim_shop/screen/seller_main_screen.dart';
import 'package:zim_shop/screen/admin_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Firebase settings (persistence, cache size, etc.)
  await FirebaseConfig.initializeSettings();
  
  // Seed initial data if needed (first run)
  await FirebaseConfig.seedInitialData();
  
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.checkCurrentUser();

    if (appState.isLoggedIn) {
      // If user is logged in, load the cart data
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.loadCart();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final appState = Provider.of<AppState>(context);
    
    if (!appState.isLoggedIn) {
      return const LoginScreen();
    }

    // Navigate based on user role
    switch (appState.currentRole) {
      case UserRole.buyer:
        return const BuyerMainScreen();
      case UserRole.seller:
        return const SellerMainScreen();
      case UserRole.admin:
        return const AdminMainScreen();
      default:
        // Fallback to login screen if role is not recognized
        return const LoginScreen();
    }
  }
}