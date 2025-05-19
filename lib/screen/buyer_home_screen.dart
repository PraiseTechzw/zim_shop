import 'package:flutter/material.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/screen/product_details_screen.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:zim_shop/widgets/category_card.dart';
import 'package:zim_shop/widgets/product_card.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({Key? key}) : super(key: key);

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<String> _locations = [];
  bool _isLoading = true;
  String? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  
  // Map of market locations to their corresponding icons
  final Map<String, IconData> _marketIcons = {
    'Mbare Musika': Icons.store,
    'Glen View Mapuranga': Icons.chair,
    'Kaguvi Motor Spares': Icons.directions_car,
    'Harare CBD': Icons.location_city,
    'Bulawayo CBD': Icons.location_city,
    'Mutare CBD': Icons.location_city,
    'Gweru CBD': Icons.location_city,
    'Masvingo CBD': Icons.location_city,
    'Other': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load products
      final products = await _supabaseService.getProducts();
      
      // Extract unique locations
      final locations = <String>{};
      
      for (final product in products) {
        if (product.location?.isNotEmpty ?? false) {
          locations.add(product.location!);
        }
      }
      
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _locations = locations.toList()..sort();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterProducts(String? location) {
    setState(() {
      _selectedLocation = location;
      if (location == null) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) => product.location == location).toList();
      }
    });
  }

  void _searchProducts(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          final title = product.name.toLowerCase();
          final description = product.description?.toLowerCase() ?? '';
          final location = product.location?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || 
                 description.contains(searchLower) ||
                 location.contains(searchLower);
        }).toList();
      }
    });
  }

  void _showAllProducts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(_selectedLocation != null 
              ? 'All Products in $_selectedLocation'
              : 'All Products'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildFilterSheet(),
                  );
                },
              ),
            ],
          ),
          body: _buildProductsGrid(),
        ),
      ),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Market',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('All Markets'),
                selected: _selectedLocation == null,
                onSelected: (selected) {
                  if (selected) {
                    _filterProducts(null);
                    Navigator.pop(context);
                  }
                },
              ),
              ..._locations.map((location) => FilterChip(
                label: Text(location),
                selected: _selectedLocation == location,
                onSelected: (selected) {
                  if (selected) {
                    _filterProducts(location);
                    Navigator.pop(context);
                  }
                },
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _searchProducts,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchProducts('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Enhanced Markets section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Markets',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedLocation != null)
                        TextButton.icon(
                          onPressed: () => _filterProducts(null),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Filter'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: _locations.isEmpty
                      ? Center(child: Text('No locations available'))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _locations.length,
                          itemBuilder: (context, index) {
                            final location = _locations[index];
                            final isSelected = location == _selectedLocation;
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () => _filterProducts(location),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _marketIcons[location] ?? Icons.location_on,
                                        size: 32,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        location,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurface,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Featured products with enhanced UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedLocation != null
                            ? 'Products in $_selectedLocation'
                            : 'Featured Products',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAllProducts,
                        icon: const Icon(Icons.grid_view),
                        label: const Text('View All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Products grid with enhanced UI
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _filteredProducts.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isSearching ? 'No products match your search' : 'No products available',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                    childCount: _filteredProducts.length,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}