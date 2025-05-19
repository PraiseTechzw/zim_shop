import 'package:flutter/material.dart';
import 'package:zim_shop/models/user.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BuyerOnboardingScreen extends StatefulWidget {
  final User user;
  final VoidCallback onCompleted;
  
  const BuyerOnboardingScreen({
    Key? key,
    required this.user,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<BuyerOnboardingScreen> createState() => _BuyerOnboardingScreenState();
}

class _BuyerOnboardingScreenState extends State<BuyerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService();
  
  bool _isLoading = false;
  int _currentStep = 0;
  
  // Form fields
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _whatsappNumberController;
  late final TextEditingController _addressController;
  
  @override
  void initState() {
    super.initState();
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _whatsappNumberController = TextEditingController(text: widget.user.whatsappNumber);
    _addressController = TextEditingController(text: widget.user.businessAddress); // Reusing businessAddress for delivery address
  }
  
  @override
  void dispose() {
    _phoneNumberController.dispose();
    _whatsappNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _supabaseService.updateBuyerProfile(
        buyerId: widget.user.id,
        phoneNumber: _phoneNumberController.text,
        whatsappNumber: _whatsappNumberController.text,
        deliveryAddress: _addressController.text,
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
              content: const Text('Your profile has been updated successfully.'),
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
                    child: Text('Failed to update profile. Please try again.'),
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
        title: const Text('Complete Your Profile'),
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
            if (_currentStep < 2) {
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
                    child: Text(_currentStep < 2 ? 'NEXT' : 'SUBMIT'),
                  ),
                ),
              ],
            );
          },
          steps: [
            // Step 1: Contact Information
            Step(
              title: const Text('Contact Information'),
              subtitle: const Text('How sellers can reach you'),
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
                      prefixIcon: FaIcon(
                        FontAwesomeIcons.whatsapp,
                        size: 24,
                        color: Colors.green,
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
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            
            // Step 2: Delivery Address
            Step(
              title: const Text('Delivery Address'),
              subtitle: const Text('Where to deliver your orders'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      hintText: 'Enter your delivery address',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your delivery address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            
            // Step 3: Terms & Conditions
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
                      'You acknowledge that your personal information will be used to process your orders and improve your shopping experience. '
                      'You are responsible for providing accurate delivery information and ensuring someone is available to receive your orders.',
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
              isActive: _currentStep >= 2,
              state: _currentStep >= 2 ? StepState.indexed : StepState.disabled,
            ),
          ],
        ),
      ),
    );
  }
} 