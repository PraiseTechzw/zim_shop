import 'package:flutter/material.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/screen/order_details_screen.dart';
import 'dart:math' as math;

class OrderCard extends StatelessWidget {
  final Order order;
  final bool isSellerView;
  final bool isAdminView;
  final Function(bool)? onStatusUpdated;
  
  const OrderCard({
    Key? key,
    required this.order,
    this.isSellerView = false,
    this.isAdminView = false,
    this.onStatusUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.id.substring(0, math.min(8, order.id.length))}...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: order.status == 'Delivered'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order.status,
                    style: TextStyle(
                      color: order.status == 'Delivered'
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${order.date.day}/${order.date.month}/${order.date.year}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (isSellerView || isAdminView) ...[
              const SizedBox(height: 4),
              Text(
                'Customer ID: ${order.userId}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            const Divider(height: 24),
            
            // Order items
            Text(
              'Items:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.product.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text(
                          '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const Divider(height: 24),
            
            // Order total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            if (isSellerView || isAdminView) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: order,
                            isSellerView: isSellerView,
                          ),
                        ),
                      );
                      if (result == true && onStatusUpdated != null) {
                        onStatusUpdated!(true);
                      }
                    },
                    child: const Text('View Details'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            order: order,
                            isSellerView: isSellerView,
                          ),
                        ),
                      );
                      if (result == true && onStatusUpdated != null) {
                        onStatusUpdated!(true);
                      }
                    },
                    child: Text(
                      order.status == 'Processing' ? 'Mark as Delivered' : 'Mark as Processing',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}