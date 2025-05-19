import 'package:flutter/material.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/widgets/cart_item_card.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;
  final bool isSellerView;
  
  const OrderDetailsScreen({
    Key? key,
    required this.order,
    this.isSellerView = false,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = false;

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final success = await _supabaseService.updateOrderStatus(
        widget.order.id,
        newStatus,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Order marked as $newStatus')),
          );
          Navigator.of(context).pop(true); // Return true to indicate update
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update order status')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id.substring(0, 8)}...'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order status
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.order.status == 'completed'
                                    ? Colors.green.withOpacity(0.1)
                                    : widget.order.status == 'processing'
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.order.status.toUpperCase(),
                                style: TextStyle(
                                  color: widget.order.status == 'completed'
                                      ? Colors.green
                                      : widget.order.status == 'processing'
                                          ? Colors.blue
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (widget.isSellerView)
                          Row(
                            children: [
                              if (widget.order.status == 'pending')
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateOrderStatus('processing'),
                                    child: const Text('Mark as Processing'),
                                  ),
                                ),
                              if (widget.order.status == 'processing') ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _updateOrderStatus('completed'),
                                    child: const Text('Mark as Completed'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Order information
                  Text(
                    'Order Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    theme,
                    [
                      _buildInfoRow('Order Date', 
                        '${widget.order.date.day}/${widget.order.date.month}/${widget.order.date.year}'),
                      _buildInfoRow('Total Amount', 
                        '\$${widget.order.totalAmount.toStringAsFixed(2)}'),
                      _buildInfoRow('Items', '${widget.order.items.length}'),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Shipping information
                  Text(
                    'Shipping Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    theme,
                    [
                      _buildInfoRow('Name', widget.order.shippingName),
                      _buildInfoRow('Email', widget.order.shippingEmail),
                      _buildInfoRow('Phone', widget.order.shippingPhone),
                      _buildInfoRow('Address', widget.order.shippingAddress),
                      _buildInfoRow('City', widget.order.shippingCity),
                      _buildInfoRow('Postal Code', widget.order.shippingPostalCode),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Order items
                  Text(
                    'Order Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.order.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Product image
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  item.product.imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quantity: ${item.quantity}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Text(
            value ?? 'Not specified',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 