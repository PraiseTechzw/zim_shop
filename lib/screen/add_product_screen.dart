import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zim_shop/models/product.dart';
import 'package:zim_shop/providers/app_state.dart';
import 'package:zim_shop/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<String> _categories = [];
  List<String> _locations = [];
  String _selectedCategory = '';
  String _selectedLocation = '';
  bool _isLoading = true;
  bool _isUploading = false;
  
  File? _imageFile;
  String? _imageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadCategoriesAndLocations();
    
    // If editing an existing product, populate the form
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _selectedCategory = widget.product!.category;
      _selectedLocation = widget.product!.location;
      _imageUrl = widget.product!.imageUrl;
    }
  }
  
  Future<void> _loadCategoriesAndLocations() async {
    try {
      final products = await _supabaseService.getProducts();
      
      // Extract unique categories and locations
      final categories = <String>{};
      final locations = <String>{};
      
      for (final product in products) {
        if (product.category != null && product.category.isNotEmpty) {
          categories.add(product.category);
        }
        if (product.location != null && product.location.isNotEmpty) {
          locations.add(product.location);
        }
      }
      
      if (mounted) {
        setState(() {
          _categories = categories.toList()..sort();
          _locations = locations.toList()..sort();
          
          // Set default values if none selected yet
          if (_selectedCategory.isEmpty && _categories.isNotEmpty) {
            _selectedCategory = _categories.first;
          } else if (_categories.isEmpty) {
            // Add some default categories if none exist yet
            _categories = ['Electronics', 'Clothing', 'Food', 'Home', 'Other'];
            _selectedCategory = 'Other';
          }
          
          if (_selectedLocation.isEmpty && _locations.isNotEmpty) {
            _selectedLocation = _locations.first;
          } else if (_locations.isEmpty) {
            // Add some default locations if none exist yet
            _locations = ['Harare', 'Bulawayo', 'Mutare', 'Gweru', 'Masvingo', 'Other'];
            _selectedLocation = 'Harare';
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories and locations: $e');
      if (mounted) {
        setState(() {
          // Add some default categories and locations if loading fails
          _categories = ['Electronics', 'Clothing', 'Food', 'Home', 'Other'];
          _locations = ['Harare', 'Bulawayo', 'Mutare', 'Gweru', 'Masvingo', 'Other'];
          _selectedCategory = 'Other';
          _selectedLocation = 'Harare';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Check if image is selected for new products
    if (widget.product == null && _imageFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product image')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final sellerId = appState.currentUser?.id;
      final sellerName = appState.currentUser?.username;
      
      if (sellerId == null || sellerName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Seller information not found')),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0.0;
      
      // Upload image if a new one was selected
      String productImageUrl = _imageUrl ?? 'assets/images/placeholder.jpg';
      if (_imageFile != null) {
        setState(() => _isUploading = true);
        final uploadedImageUrl = await _supabaseService.uploadProductImage(_imageFile, sellerId);
        if (uploadedImageUrl != null) {
          productImageUrl = uploadedImageUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image. Using default image.')),
          );
        }
        setState(() => _isUploading = false);
      }
      
      if (widget.product == null) {
        // Add new product
        final newProduct = Product(
          id: '',  // Will be assigned by database
          name: name,
          description: description,
          price: price,
          imageUrl: productImageUrl,
          category: _selectedCategory,
          location: _selectedLocation,
          sellerId: sellerId,
          sellerName: sellerName,
        );
        
        final success = await _supabaseService.addProduct(newProduct);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add product. Please try again.')),
          );
        }
      } else {
        // Update existing product
        final updatedProduct = Product(
          id: widget.product!.id,
          name: name,
          description: description,
          price: price,
          imageUrl: productImageUrl,
          category: _selectedCategory,
          location: _selectedLocation,
          sellerId: sellerId,
          sellerName: sellerName,
        );
        
        final success = await _supabaseService.updateProduct(updatedProduct);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product updated successfully')),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update product. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _saveProduct,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                Center(
                  child: GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Stack(
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _imageUrl != null && !_imageUrl!.contains('assets/images')
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _imageFile == null && (_imageUrl == null || _imageUrl!.contains('assets/images'))
                              ? const Center(
                                  child: Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                )
                              : null,
                        ),
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _imageFile != null || (_imageUrl != null && !_imageUrl!.contains('assets/images'))
                                  ? Icons.edit
                                  : Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_imageFile != null || (_imageUrl != null && !_imageUrl!.contains('assets/images')))
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _imageFile = null;
                          if (widget.product == null) {
                            _imageUrl = null;
                          }
                        });
                      },
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Product details
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
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
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
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
                  decoration: InputDecoration(
                    labelText: 'Price (\$)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    if (double.tryParse(value)! <= 0) {
                      return 'Price must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category_outlined),
                  ),
                  items: _categories.map((category) {
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
                  decoration: InputDecoration(
                    labelText: 'Market Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  items: _locations.map((location) {
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
                  icon: _isUploading || _isLoading 
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(widget.product == null ? 'Add Product' : 'Update Product'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}