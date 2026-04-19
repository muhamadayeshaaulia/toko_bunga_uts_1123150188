import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../dashboard/data/model/product_model.dart';
import '../../../dashboard/presentation/providers/product_provider.dart';

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
  
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
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
          children: [
            Text(
              isEdit ? 'Edit Produk 716' : 'Tambah Produk Baru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Preview Gambar
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : (isEdit) 
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.product!.imageUrl, fit: BoxFit.cover))
                        : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Harga', border: OutlineInputBorder()),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: productProvider.isLoading 
                ? null 
                : () async {
                  final name = _nameController.text;
                  final price = double.tryParse(_priceController.text) ?? 0;
                  final stock = int.tryParse(_stockController.text) ?? 0;

                  bool success;
                  if (isEdit) {
                    success = await context.read<ProductProvider>().updateProduct(
                      widget.product!.id,
                      name: name,
                      price: price,
                      category: widget.product!.category, 
                      stock: stock,
                      imageFile: _imageFile,
                    );
                  } else {
                    success = await context.read<ProductProvider>().createProduct(
                      name: name,
                      price: price,
                      category: "Makanan", 
                      stock: stock,
                      imageFile: _imageFile,
                    );
                  }

                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? "Produk Berhasil Diupdate!" : "Produk Berhasil Ditambah!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEdit ? Colors.blue : Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: productProvider.isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}