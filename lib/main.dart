import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/providers/theme_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/screen/buyer_main_screen.dart';
import 'package:zim_shop/screen/seller_main_screen.dart';
import 'package:zim_shop/screen/admin_main_screen.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/services/paynow_service.dart';

// Paynow test integration credentials
const String paynowIntegrationId = 'YOUR_PAYNOW_INTEGRATION_ID';
const String paynowIntegrationKey = 'YOUR_PAYNOW_INTEGRATION_KEY';
const String paynowResultUrl = 'https://example.com/api/paynow/update';
const String paynowReturnUrl = 'https://example.com/checkout/return';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService().initialize();
  
  // Initialize Paynow
  PaynowService(
    integrationId: paynowIntegrationId,
    integrationKey: paynowIntegrationKey,
    resultUrl: paynowResultUrl,
    returnUrl: paynowReturnUrl,
  );
  
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
      home: const AuthCheckWrapper(),
    );
  }
}

class AuthCheckWrapper extends StatefulWidget {
  const AuthCheckWrapper({Key? key}) : super(key: key);

  @override
  State<AuthCheckWrapper> createState() => _AuthCheckWrapperState();
}

class _AuthCheckWrapperState extends State<AuthCheckWrapper> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.checkAuthState();
    
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
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
        return const LoginScreen();
    }
  }
}