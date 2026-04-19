import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  
  File? _imageFile; // File hasil crop

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _descriptionController.text = widget.product!.description;
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

  // Fungsi memanggil ImageService untuk Pick + Crop
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
            // Header Form
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
                  height: 160,
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
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 50, color: Colors.redAccent.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                const Text("Ambil & Potong Foto", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Input Nama Produk
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Produk',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Harga',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stok',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi Produk',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
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
                        const SnackBar(content: Text("Nama dan Harga harus valid!")),
                      );
                      return;
                    }

                    bool success;
                    if (isEdit) {
                      success = await context.read<ProductProvider>().updateProduct(
                        widget.product!.id,
                        name: name,
                        price: price,
                        category: widget.product!.category,
                        description: desc,
                        stock: stock,
                        imageFile: _imageFile,
                      );
                    } else {
                      success = await context.read<ProductProvider>().createProduct(
                        name: name,
                        price: price,
                        category: "Umum",
                        description: desc,
                        stock: stock,
                        imageFile: _imageFile,
                      );
                    }

                    if (success && context.mounted) {
                      Navigator.pop(context);
                      NotificationService.showNotification(
                        title: "716_Production",
                        body: "Produk $name berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}!",
                      );
                    }
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEdit ? Colors.blue : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: productProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEdit ? 'UPDATE PRODUK' : 'SIMPAN PRODUK',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}