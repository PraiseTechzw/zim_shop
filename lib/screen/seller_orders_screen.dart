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
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  
  final List<String> _statusFilters = ['All', 'Pending', 'Processing', 'Completed'];
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  void _filterOrders() {
    setState(() {
      if (_selectedStatus == 'All') {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) => 
          order.status.toLowerCase() == _selectedStatus.toLowerCase()
        ).toList();
      }
    });
  }
  
  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final sellerId = appState.currentUser?.id;
      
      if (sellerId == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final orders = await _supabaseService.getSellerOrders(sellerId);
      
      if (mounted) {
        setState(() {
          _orders = orders;
          _filterOrders(); // Apply initial filter
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
      
    return Scaffold(
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = status;
                        _filterOrders();
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Orders list
          Expanded(
            child: _filteredOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Orders Found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedStatus == 'All' 
                          ? 'You haven\'t received any orders yet'
                          : 'No ${_selectedStatus.toLowerCase()} orders',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return OrderCard(
                        order: order,
                        isSellerView: true,
                        onStatusUpdated: (updated) {
                          if (updated) {
                            _loadOrders();
                          }
                        },
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }
}