import 'package:flutter/material.dart';
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/services/supabase_service.dart';

class SellerOnboardingScreen extends StatefulWidget {
  final User user;
  final VoidCallback onCompleted;
  
  const SellerOnboardingScreen({
    Key? key,
    required this.user,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<SellerOnboardingScreen> createState() => _SellerOnboardingScreenState();
}

class _SellerOnboardingScreenState extends State<SellerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  int _currentStep = 0;
  
  // Form fields
  late final TextEditingController _businessNameController;
  late final TextEditingController _businessAddressController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _whatsappNumberController;
  late final TextEditingController _sellerBioController;
  
  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.user.businessName);
    _businessAddressController = TextEditingController(text: widget.user.businessAddress);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _whatsappNumberController = TextEditingController(text: widget.user.whatsappNumber);
    _sellerBioController = TextEditingController(text: widget.user.sellerBio);
  }
  
  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _phoneNumberController.dispose();
    _whatsappNumberController.dispose();
    _sellerBioController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _supabaseService.updateSellerProfile(
        sellerId: widget.user.id,
        businessName: _businessNameController.text,
        businessAddress: _businessAddressController.text,
        phoneNumber: _phoneNumberController.text,
        whatsappNumber: _whatsappNumberController.text,
        sellerBio: _sellerBioController.text,
      );
      
      if (success) {
        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Success!'),
                ],
              ),
              content: const Text('Your seller profile has been updated successfully.'),
              actions: [
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    widget.onCompleted(); // Call completion callback
                  },
                  child: const Text('CONTINUE'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to update seller profile. Please try again.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('An error occurred: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Onboarding'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() {
                _currentStep += 1;
              });
            } else {
              _submitForm();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep -= 1;
              });
            }
          },
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('BACK'),
                    ),
                  ),
                if (_currentStep > 0)
                  const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep < 3 ? 'NEXT' : 'SUBMIT'),
                  ),
                ),
              ],
            );
          },
          steps: [
            // Step 1: Business Information
            Step(
              title: const Text('Business Information'),
              subtitle: const Text('Tell us about your business'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _businessNameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                      hintText: 'Enter your business name',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your business name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _businessAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Business Address',
                      hintText: 'Enter your business address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your business address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            
            // Step 2: Contact Information
            Step(
              title: const Text('Contact Information'),
              subtitle: const Text('How customers can reach you'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _phoneNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _whatsappNumberController,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Number',
                      hintText: 'Enter your WhatsApp number',
                      prefixIcon: Image.asset(
                        'assets/images/whatsapp_icon.png', 
                        width: 24, 
                        height: 24,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your WhatsApp number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            
            // Step 3: Seller Bio
            Step(
              title: const Text('About You'),
              subtitle: const Text('Tell customers about yourself'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _sellerBioController,
                    decoration: const InputDecoration(
                      labelText: 'Seller Bio',
                      hintText: 'Tell customers about you and your products',
                      prefixIcon: Icon(Icons.person),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your bio';
                      }
                      if (value.length < 50) {
                        return 'Bio should be at least 50 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            ),
            
            // Step 4: Terms & Conditions
            Step(
              title: const Text('Terms & Conditions'),
              subtitle: const Text('Review and accept our terms'),
              content: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'By proceeding, you agree to the ZimMarket Terms of Service and Privacy Policy. '
                      'You acknowledge that your seller account may be subject to approval before you can list products. '
                      'ZimMarket takes a 5% commission on all sales. '
                      'You are responsible for the accuracy of your listings and timely delivery of products.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('I agree to the Terms & Conditions'),
                    value: true, // This would be a state variable in a real app
                    onChanged: (value) {
                      // Would update state in a real app
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
              state: _currentStep >= 3 ? StepState.indexed : StepState.disabled,
            ),
          ],
        ),
      ),
    );
  }
} 