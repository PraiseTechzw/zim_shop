import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/providers/theme_provider.dart';
import 'package:zim_shop/screen/auth/login_screen.dart';
import 'package:zim_shop/screen/auth/reset_password_screen.dart';
import 'package:zim_shop/screen/buyer_main_screen.dart';
import 'package:zim_shop/screen/seller_main_screen.dart';
import 'package:zim_shop/screen/admin_main_screen.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/services/paynow_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Paynow test integration credentials
const String paynowIntegrationId = 'YOUR_PAYNOW_INTEGRATION_ID';
const String paynowIntegrationKey = 'YOUR_PAYNOW_INTEGRATION_KEY';
const String paynowResultUrl = 'https://example.com/api/paynow/update';
const String paynowReturnUrl = 'https://example.com/checkout/return';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services with error handling
  try {
    // Initialize Supabase with custom deeplink handling
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode,
      authOptions: const FlutterAuthClientOptions(
        // Disable automatic deeplink handling so we can handle it ourselves
        detectSessionInUri: false,
      ),
    );
    
    // Initialize Paynow
    PaynowService(
      integrationId: paynowIntegrationId,
      integrationKey: paynowIntegrationKey,
      resultUrl: paynowResultUrl,
      returnUrl: paynowReturnUrl,
    );
    
    // Set up custom deeplink handling
    setupDeeplinkHandling();
    
    // Everything initialized successfully, start the app
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: ZimMarketApp(navigatorKey: navigatorKey),
      ),
    );
  } catch (e) {
    // If there's an error during initialization, show an error screen
    debugPrint('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Unable to connect to server',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // This will restart the app
                    main();
                  },
                  child: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Sets up custom deep link handling
void setupDeeplinkHandling() {
  final appLinks = AppLinks();
  
  // Listen for initial links - this includes the app being opened with a link
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      handleDeepLink(uri);
    }
  });
  
  // Listen for links when app is already running
  appLinks.uriLinkStream.listen((uri) {
    handleDeepLink(uri);
  }, onError: (error) {
    debugPrint('Error receiving deep link: $error');
  });
}

// Handle the deeplink and process authentication flows
Future<void> handleDeepLink(Uri uri) async {
  final supabase = Supabase.instance.client;
  
  try {
    debugPrint('Received deeplink: $uri');
    
    // Check if it's an auth link by looking for the 'code' parameter
    if (uri.queryParameters.containsKey('code')) {
      // Process the auth link
      final response = await supabase.auth.getSessionFromUrl(uri);
      
      // Check if this is a password recovery flow
      // This can be detected by examining the URI or checking the response
      final isPasswordRecovery = uri.fragment.contains('type=recovery') || 
                               uri.toString().contains('type=recovery');
      
      if (isPasswordRecovery) {
        debugPrint('Detected password recovery flow');
        
        // Get the AppState instance and set password recovery state
        // This will notify all listeners about the password recovery
        final navigatorKey = GlobalKey<NavigatorState>();
        final context = navigatorKey.currentContext;
        
        if (context != null) {
          // Use the context to access the provider
          Provider.of<AppState>(context, listen: false).setPasswordRecovery(true);
        } else {
          // Fallback if context is not available
          // Wait for the app to initialize and then set the state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              Provider.of<AppState>(context, listen: false).setPasswordRecovery(true);
            }
          });
        }
      }
    }
  } catch (e) {
    debugPrint('Error handling deeplink: $e');
  }
}

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ZimMarketApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const ZimMarketApp({
    Key? key,
    required this.navigatorKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      navigatorKey: navigatorKey,
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
    
    // If password recovery is detected, show the reset password screen
    if (appState.isPasswordRecovery) {
      return const ResetPasswordScreen();
    }
    
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