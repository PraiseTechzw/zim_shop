import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
  import 'package:zim_shop/mock_data.dart';
  import 'package:zim_shop/models/product.dart';
  import 'package:zim_shop/providers/app_state.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  
  const AddProductScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = MockData.categories.first;
  String _selectedLocation = MockData.locations.first;
  
  @override
  void initState() {
    super.initState();
    
    // If editing an existing product, populate the form
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _selectedCategory = widget.product!.category;
      _selectedLocation = widget.product!.location;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final appState = Provider.of<AppState>(context, listen: false);
    final sellerId = appState.currentUser?.id;
    final sellerName = appState.currentUser?.username;
    
    if (sellerId == null || sellerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Seller information not found')),
      );
      return;
    }
    
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    if (widget.product == null) {
      // Add new product
      final newProduct = Product(
        id: MockData.products.length + 1,
        name: name,
        description: description,
        price: price,
        imageUrl: 'assets/images/placeholder.jpg',
        category: _selectedCategory,
        location: _selectedLocation,
        sellerId: sellerId,
        sellerName: sellerName,
      );
      
      MockData.products.add(newProduct);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
    } else {
      // Update existing product
      final index = MockData.products.indexWhere((p) => p.id == widget.product!.id);
      if (index != -1) {
        MockData.products[index] = Product(
          id: widget.product!.id,
          name: name,
          description: description,
          price: price,
          imageUrl: widget.product!.imageUrl,
          category: _selectedCategory,
          location: _selectedLocation,
          sellerId: sellerId,
          sellerName: sellerName,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    }
    
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Center(
                child: GestureDetector(
                  onTap: () {
                    // Simulate image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image picker would open here')),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Simulate image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image picker would open here')),
                    );
                  },
                  child: const Text('Upload Image'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Product details
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: MockData.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  labelText: 'Market Location',
                  border: OutlineInputBorder(),
                ),
                items: MockData.locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 32),
              
              FilledButton.icon(
                onPressed: _saveProduct,
                icon: const Icon(Icons.save),
                label: Text(widget.product == null ? 'Add Product' : 'Update Product'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}