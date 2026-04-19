import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../dashboard/data/model/product_model.dart';
import '../../../dashboard/presentation/providers/product_provider.dart';
import '../../../../core/services/image_service.dart';
import '../../../../core/services/notification_service.dart';

class ProductFormSheet extends StatefulWidget {
  final ProductModel? product;

  const ProductFormSheet({super.key, this.product});

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = "Makanan"; 
  final List<String> _categories = ["Makanan", "Minuman", "Cemilan", "Lainnya"];

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _descriptionController.text = widget.product!.description ?? "";
      if (_categories.contains(widget.product!.category)) {
        _selectedCategory = widget.product!.category;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleImageSelection() async {
    final File? cropped = await ImageService.pickAndCropImage(context);
    if (cropped != null) {
      setState(() {
        _imageFile = cropped;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final productProvider = context.watch<ProductProvider>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Produk 716' : 'Tambah Produk Baru',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _handleImageSelection,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : (isEdit && widget.product!.imageUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.network(widget.product!.imageUrl, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder(), prefixText: 'Rp '),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: productProvider.isLoading 
                ? null 
                : () async {
                    final name = _nameController.text;
                    final price = double.tryParse(_priceController.text) ?? 0;
                    final stock = int.tryParse(_stockController.text) ?? 0;
                    final desc = _descriptionController.text;

                    if (name.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Data tidak valid!")),
                      );
                      return;
                    }

                    bool success;
                    if (isEdit) {
                      success = await context.read<ProductProvider>().updateProduct(
                        widget.product!.id,
                        name: name,
                        price: price,
                        category: _selectedCategory, 
                        description: desc,
                        stock: stock,
                        imageFile: _imageFile,
                      );
                    } else {
                      success = await context.read<ProductProvider>().createProduct(
                        name: name,
                        price: price,
                        category: _selectedCategory,
                        description: desc,
                        stock: stock,
                        imageFile: _imageFile,
                      );
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      NotificationService.showNotification(
                        title: "716_Production",
                        body: "Produk $name masuk kategori $_selectedCategory!",
                      );
                    }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEdit ? Colors.blue : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: productProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEdit ? 'UPDATE PRODUK' : 'SIMPAN PRODUK', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}