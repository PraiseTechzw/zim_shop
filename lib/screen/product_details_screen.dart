import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/providers/cart_provider.dart';
import 'package:zim_shop/screen/checkout_screen.dart';
import 'package:zim_shop/widgets/quantity_selector.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';


class ProductDetailsScreen extends StatefulWidget {
  final Product product;
  
  const ProductDetailsScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: widget.product.imageUrl.startsWith('http')
                  ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Error loading product image: $error');
                        return _buildDefaultProductImage(theme);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        // If loading takes too long, show default image
                        if (loadingProgress.expectedTotalBytes != null &&
                            loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! < 0.1) {
                          return _buildDefaultProductImage(theme);
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultProductImage(theme);
                      },
                    ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '\$${widget.product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.locationDot, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Seller information section
                  _buildSellerInfoSection(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Quantity selector
                  Row(
                    children: [
                      Text(
                        'Quantity:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      QuantitySelector(
                        value: _quantity,
                        onChanged: (value) {
                          setState(() {
                            _quantity = value;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final cartProvider = Provider.of<CartProvider>(context, listen: false);
                            cartProvider.addItem(widget.product, _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.product.name} added to cart'),
                                action: SnackBarAction(
                                  label: 'VIEW CART',
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: const FaIcon(FontAwesomeIcons.cartShopping),
                          label: const Text('Add to Cart'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            final cartProvider = Provider.of<CartProvider>(context, listen: false);
                            cartProvider.addItem(widget.product, _quantity);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CheckoutScreen(),
                              ),
                            );
                          },
                          icon: const FaIcon(FontAwesomeIcons.creditCard),
                          label: const Text('Buy Now'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSellerInfoSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seller Information',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Show verification badge if seller is verified
              if (widget.product.sellerIsVerified == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Seller name
          Row(
            children: [
              Icon(Icons.person, 
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.product.sellerName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Seller email if available
          if (widget.product.sellerEmail != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.email, 
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.product.sellerEmail!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          
          // Seller ID (for admin/reference purposes)
          Row(
            children: [
              Icon(Icons.badge, 
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'ID: ${widget.product.sellerId.substring(0, Math.min(8, widget.product.sellerId.length))}...',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Seller rating if available
          if (widget.product.sellerRating != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.star, 
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.product.sellerRating!.toStringAsFixed(1)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildRatingStars(widget.product.sellerRating!),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Contact buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // WhatsApp contact button if available
              if (widget.product.sellerWhatsapp != null)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: _buildWhatsAppButton(theme),
                ),
                
              // General contact button or full-width button if WhatsApp not available
              SizedBox(
                width: widget.product.sellerWhatsapp != null
                    ? MediaQuery.of(context).size.width * 0.4
                    : double.infinity,
                child: _buildContactButton(theme),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // WhatsApp button
  Widget _buildWhatsAppButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: () => _contactSellerViaWhatsApp(),
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
      label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
  
  // Regular contact button
  Widget _buildContactButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: () => _contactSeller(),
      icon: const FaIcon(FontAwesomeIcons.message, size: 16),
      label: const Text('Contact', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
  
  // Contact via WhatsApp
  Future<void> _contactSellerViaWhatsApp() async {
    if (widget.product.sellerWhatsapp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp number not available')),
      );
      return;
    }
    
    try {
      // Format number to remove any non-digit characters and ensure it starts with country code
      String phoneNumber = widget.product.sellerWhatsapp!.replaceAll(RegExp(r'[^\d]'), '');
      
      // Add Zimbabwe country code if not present
      if (!phoneNumber.startsWith('263')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '263${phoneNumber.substring(1)}';
        } else {
          phoneNumber = '263$phoneNumber';
        }
      }
      
      // Create message template
      final message = 'Hello, I am interested in your product "${widget.product.name}" on ZimMarket. Is it still available?';
      
      // Try different URL formats
      final urls = [
        // WhatsApp Business API URL
        Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}'),
        // WhatsApp Web URL
        Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'),
        // WhatsApp native URL
        Uri.parse('whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}'),
      ];

      bool launched = false;
      for (final url in urls) {
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
            launched = true;
            break;
          }
        } catch (e) {
          debugPrint('Failed to launch URL: $url');
          continue;
        }
      }

      if (!launched) {
        // If all URL formats fail, show dialog with options
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Open WhatsApp'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please choose an option:'),
                  const SizedBox(height: 16),
                  Text('Phone: $phoneNumber'),
                  const SizedBox(height: 8),
                  Text('Message: $message'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phoneNumber));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number copied to clipboard')),
                    );
                  },
                  child: const Text('COPY NUMBER'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open WhatsApp'),
            action: SnackBarAction(
              label: 'COPY NUMBER',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.product.sellerWhatsapp!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number copied to clipboard')),
                );
              },
            ),
          ),
        );
      }
    }
  }
  
  // Regular contact method
  void _contactSeller() {
    // This would launch an in-app chat feature or email in a real app
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('In-app messaging coming soon!'),
        action: SnackBarAction(
          label: 'EMAIL',
          onPressed: () async {
            if (widget.product.sellerEmail == null) return;
            
            try {
              final emailUri = Uri(
                scheme: 'mailto',
                path: widget.product.sellerEmail,
                queryParameters: {
                  'subject': 'Regarding your product on ZimMarket: ${widget.product.name}',
                },
              );
              
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(
                  emailUri,
                  mode: LaunchMode.externalNonBrowserApplication,
                );
              } else {
                throw Exception('Could not launch email client');
              }
            } catch (e) {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Contact Seller'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${widget.product.sellerEmail}'),
                        const SizedBox(height: 8),
                        Text('Subject: Regarding your product on ZimMarket: ${widget.product.name}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('CANCEL'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.product.sellerEmail!));
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email address copied to clipboard')),
                          );
                        },
                        child: const Text('COPY EMAIL'),
                      ),
                    ],
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }
  
  // Helper method to build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          // Full star
          return FaIcon(FontAwesomeIcons.solidStar, color: Colors.amber, size: 14);
        } else if (index < rating.ceil() && index > rating.floor()) {
          // Half star
          return FaIcon(FontAwesomeIcons.starHalfStroke, color: Colors.amber, size: 14);
        } else {
          // Empty star
          return FaIcon(FontAwesomeIcons.star, color: Colors.amber, size: 14);
        }
      }),
    );
  }

  // Default product image widget
  Widget _buildDefaultProductImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.image,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for math operations since we can't use dart:math directly in the widget tree
class Math {
  static int min(int a, int b) => a < b ? a : b;
}