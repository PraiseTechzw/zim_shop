import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/screen/seller_dashboard_screen.dart';
import 'package:zim_shop/screen/seller_onboarding_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    
    if (user == null) {
      // This shouldn't happen, but just in case
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You need to be logged in as a seller'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Check if seller profile is complete
    if (!appState.isSellerProfileComplete) {
      return SellerOnboardingScreen(
        user: user,
        onCompleted: () {
          // Refresh user data and rebuild
          appState.refreshUser().then((_) {
            setState(() {});
          });
        },
      );
    }
    
    // Show seller dashboard if profile is complete
    return const SellerDashboardScreen();
  }
} 