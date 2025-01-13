import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'transaction_model.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AddTransaction extends StatefulWidget {
  final Function(String, double, DateTime, String?) addTransaction;
  final Transaction? existingTransaction; // null jika mode tambah

  AddTransaction({
    required this.addTransaction,
    this.existingTransaction,
  });

  @override
  _AddTransactionState createState() => _AddTransactionState();
}

class _AddTransactionState extends State<AddTransaction> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late DateTime _selectedDate;
  String? _existingImageUrl;
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    // Prefill data jika ada transaksi yang diedit
    _titleController = TextEditingController(
      text: widget.existingTransaction?.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingTransaction?.amount.toString() ?? '',
    );
    _selectedDate = widget.existingTransaction?.date ?? DateTime.now();
    _existingImageUrl = widget.existingTransaction?.imageUrl;
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text);
      final date = _selectedDate;
      String? imageUrl = _existingImageUrl;

      try {
        // Upload gambar baru jika ada
        if (_selectedImage != null) {
          print('Memulai upload gambar...');
          final ref = FirebaseStorage.instance
              .ref()
              .child('transaction_receipts')
              .child('${DateTime.now().toIso8601String()}.jpg');
          await ref.putFile(_selectedImage!);
          imageUrl = await ref.getDownloadURL();
          print('Gambar berhasil diunggah. URL: $imageUrl');
        }

        widget.addTransaction(title, amount, date, imageUrl);

        // Tampilkan pesan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaksi berhasil disimpan')),
        );

        // Navigasi kembali ke halaman sebelumnya
        Navigator.of(context).pop(true);
      } catch (error) {
        // Tampilkan pesan error jika terjadi kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan transaksi: $error')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> requestPermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
}

Future<void> downloadAndSaveImage(String imageUrl) async {
  // Meminta izin penyimpanan
  await requestPermission();

  try {
    // Download gambar menggunakan Dio
    var response = await Dio().get(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    // Simpan gambar ke galeri
    final result = await ImageGallerySaverPlus.saveImage(
      Uint8List.fromList(response.data),
      quality: 80,
      name: "downloaded_image",
    );

    if (result['isSuccess']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gambar sedang diunduh!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan gambar.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTransaction == null
            ? 'Tambah Transaksi'
            : 'Edit Transaksi'),
actions: widget.existingTransaction != null
    ? [
        IconButton(
          icon: Icon(Icons.download),
          onPressed: () async {
            if (_existingImageUrl != null) {
              await downloadAndSaveImage(_existingImageUrl!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gambar berhasil tersimpan di Galeri~')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tidak ada gambar untuk diunduh')),
              );
            }
          },
        ),
      ]
    : null,

      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Judul'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan judul transaksi';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan jumlah';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Harap masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tanggal: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      ),
                    ),
                    TextButton(
                      onPressed: _presentDatePicker,
                      child: Text('Pilih Tanggal'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                _existingImageUrl != null && _selectedImage == null
                    ? Column(
                        children: [
                          Image.network(
                            _existingImageUrl!,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image, size: 100),
                          ),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image),
                            label: Text('Ganti Gambar'),
                          ),
                        ],
                      )
                    : _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            height: MediaQuery.of(context).size.height * 0.3,
                            width: MediaQuery.of(context).size.width * 0.5,
                            fit: BoxFit.cover,
                          )
                        : TextButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.image),
                            label: Text('Pilih Gambar'),
                          ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitData,
                  child: Text(widget.existingTransaction == null
                      ? 'Tambah Transaksi'
                      : 'Simpan Perubahan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
