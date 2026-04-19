import 'package:flutter/material.dart';
import '../../../dashboard/data/model/product_model.dart';

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
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Jika sedang EDIT, isi field dengan data lama
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _imageUrlController.text = widget.product!.imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 12),
          TextField(
            controller: _imageUrlController,
            decoration: const InputDecoration(labelText: 'URL Gambar', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Logika simpan atau update akan di sini nanti
              Navigator.pop(context);
              debugPrint("Data Disimpan: ${_nameController.text}");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isEdit ? Colors.blue : Colors.redAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}