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

// Supabase configuration constants
// These need to match the ones in SupabaseService
const String supabaseUrl = 'https://gkyeijnygndqqstxucpn.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdreWVpam55Z25kcXFzdHh1Y3BuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1Nzk5NzcsImV4cCI6MjA2MzE1NTk3N30.kgLfES9rO2VsIkCErg556pbXc3UZEaSjuoX7SHcRQFU';

// Paynow test integration credentials
const String paynowIntegrationId = ' 20889';
const String paynowIntegrationKey = ' 00e58958-d6a8-4a0a-84ed-bf0b3bc322f2';
const String paynowResultUrl = 'https://example.com/api/paynow/update';
const String paynowReturnUrl = 'https://example.com/checkout/return';

// Global navigator key to access context from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global flag to track if a password recovery flow is pending
// This is used when the app is still initializing
bool _isPasswordRecoveryPending = false;

// Track if the app is already handling a deep link
bool _isHandlingDeepLink = false;

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
    
    // Create the AppState provider that will be used throughout the app
    final appState = AppState();
    
    // Setup custom deeplink handling with AppState
    setupDeeplinkHandling(appState);
    
    // Initialize AppState (which will initialize SupabaseService properly)
    await appState.initialize();
    
    // Everything initialized successfully, start the app
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appState),
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
void setupDeeplinkHandling(AppState appState) {
  final appLinks = AppLinks();
  
  // Listen for initial links - this includes the app being opened with a link
  // Using catchError to ensure we don't crash if there's an issue
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      debugPrint('Got initial deep link: $uri');
      handleDeepLink(uri, appState);
    }
  }).catchError((error) {
    debugPrint('Error getting initial deep link: $error');
  });
  
  // Listen for links when app is already running
  appLinks.uriLinkStream.listen((uri) {
    debugPrint('Got deep link from stream: $uri');
    handleDeepLink(uri, appState);
  }, onError: (error) {
    debugPrint('Error receiving deep link: $error');
  });
}

// Handle the deeplink and process authentication flows
Future<void> handleDeepLink(Uri uri, AppState appState) async {
  try {
    // Prevent multiple simultaneous handling of the same deep link
    if (_isHandlingDeepLink) {
      debugPrint('Already handling a deep link, ignoring: $uri');
      return;
    }
    
    _isHandlingDeepLink = true;
    debugPrint('Handling deeplink: $uri');
    
    final supabase = Supabase.instance.client;
    
    // Check if it's an auth link by looking for the 'code' parameter
    if (uri.queryParameters.containsKey('code')) {
      // Process the auth link
      try {
        final response = await supabase.auth.getSessionFromUrl(uri);
        debugPrint('Successfully processed auth URL: $uri');
        
        // Check if this is a password recovery flow
        final isPasswordRecovery = uri.fragment.contains('type=recovery') || 
                               uri.toString().contains('type=recovery');
        
        if (isPasswordRecovery) {
          debugPrint('Detected password recovery flow');
          
          // Set global flag and update AppState
          _isPasswordRecoveryPending = true;
          
          // Update AppState if possible
          try {
            appState.setPasswordRecovery(true);
            debugPrint('Successfully set password recovery state in AppState');
          } catch (e) {
            debugPrint('Error setting password recovery state in AppState: $e');
          }
          
          // Also try to use the navigator if available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              debugPrint('Navigating to ResetPasswordScreen using Navigator');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
              );
            } else {
              debugPrint('Context not available for navigation');
            }
          });
        } else {
          // Normal sign-in flow, refresh the user state
          await appState.checkAuthState();
        }
      } catch (e) {
        debugPrint('Error processing auth URL: $e');
      }
    }
  } catch (e) {
    debugPrint('Error handling deeplink: $e');
  } finally {
    _isHandlingDeepLink = false;
  }
}

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
      initialRoute: '/',
      routes: {
        '/': (context) {
          // Use a unique key based on login state to force rebuild when login state changes
          final appState = Provider.of<AppState>(context);
          return AuthCheckWrapper(
            key: ValueKey('auth_check_${appState.isLoggedIn}_${appState.currentRole}'),
          );
        },
        '/login': (context) => const LoginScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/buyer': (context) => const BuyerMainScreen(),
        '/seller': (context) => const SellerMainScreen(),
        '/admin': (context) => const AdminMainScreen(),
      },
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
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Make sure AppState is initialized
      if (!appState.isInitialized) {
        await appState.initialize();
      }
      
      // Check authentication state
      await appState.checkAuthState();
      
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('Error in AuthCheckWrapper: $e');
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
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
    
    // If password recovery is detected from either the app state or the global flag
    if (appState.isPasswordRecovery || _isPasswordRecoveryPending) {
      debugPrint("Showing ResetPasswordScreen due to password recovery flag");
      
      // Clear the global flag since we're now handling it
      _isPasswordRecoveryPending = false;
      
      // If not already set in the app state, set it now
      if (!appState.isPasswordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.setPasswordRecovery(true);
        });
      }
      
      // Use named route navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/reset-password');
      });
      
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!appState.isLoggedIn) {
      debugPrint("User not logged in, showing LoginScreen");
      
      // Use named route navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Navigate based on user role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      String route;
      
      switch (appState.currentRole) {
        case UserRole.buyer:
          route = '/buyer';
          break;
        case UserRole.seller:
          route = '/seller';
          break;
        case UserRole.admin:
          route = '/admin';
          break;
        default:
          route = '/login';
          break;
      }
      
      debugPrint("User logged in as ${appState.currentRole}, navigating to $route");
      Navigator.of(context).pushReplacementNamed(route);
    });
    
    // Show loading screen while navigating
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}