import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/order.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/widgets/order_card.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({Key? key}) : super(key: key);

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Order> _sellerOrders = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  Future<void> _loadOrders() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final sellerId = appState.currentUser?.id;
    
    if (sellerId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final orders = await _supabaseService.getSellerOrders(sellerId);
      
      if (mounted) {
        setState(() {
          _sellerOrders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading seller orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_sellerOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Orders Yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your orders will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
      padding: const EdgeInsets.all(16),
        itemCount: _sellerOrders.length,
      itemBuilder: (context, index) {
          final order = _sellerOrders[index];
        return OrderCard(
          order: order,
          isSellerView: true,
        );
      },
      ),
    );
  }
}