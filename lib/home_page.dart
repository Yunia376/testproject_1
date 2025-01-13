import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'settings_page.dart';
import 'add_transaction.dart';
import 'transaction_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<Transaction> _transactions = [];
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onBottomNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        _tabController.index = 1; 
      } else {
        _tabController.index = 0;
      }
    });
  }

  void _addTransaction(String title, double amount, DateTime date, String? imageUrl) async {
    final newTx = Transaction(title: title, amount: amount, date: date, id: '', imageUrl: imageUrl);

    final docRef = await firestore.FirebaseFirestore.instance.collection('transactions').add({
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
    });

    setState(() {
      _transactions.add(Transaction(
        id: docRef.id,
        title: title,
        amount: amount,
        date: date,
        imageUrl: imageUrl,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi berhasil ditambahkan')),
    );
  }

  void _fetchTransactions() async {
    final querySnapshot =
        await firestore.FirebaseFirestore.instance.collection('transactions').get();

    final fetchedTransactions = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Transaction(
        id: doc.id,
        title: data['title'],
        amount: data['amount'],
        date: DateTime.parse(data['date']),
        imageUrl: data['imageUrl'],
      );
    }).toList();

    setState(() {
      _transactions = fetchedTransactions;
    });
  }



void _showSnackbar(String message) {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    ),
  );
}





Future<void> deleteTransaction(String transactionId) async {
  try {
    await firestore.FirebaseFirestore.instance
        .collection('transactions')
        .doc(transactionId)
        .delete();

    // Hapus dari state
    setState(() {
      _transactions.removeWhere((transaction) => transaction.id == transactionId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi berhasil dihapus')),
    );
  } catch (e) {
    print('Gagal menghapus transaksi: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menghapus transaksi: $e')),
    );
  }
}




  void _startAddTransaction(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransaction(addTransaction: _addTransaction),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil ditambahkan')),
      );
    }
  }

  void _onThemeChanged(bool isDark) {
    setState(() {
      _isDarkMode = isDark;
    });
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(onThemeChanged: _onThemeChanged),
      ),
    );
  }

void _showTransactionOptions(Transaction transaction) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tampilkan gambar jika ada
          transaction.imageUrl != null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                    transaction.imageUrl!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                )
              : SizedBox(), // Jika tidak ada gambar, tidak menampilkan apa-apa

          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Data/Download Gambar'),
            onTap: () {
              Navigator.of(ctx).pop(); // Tutup BottomSheet
              _startEditTransaction(transaction);
            },
          ),


          // Tombol Hapus Item
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Hapus Item', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.of(ctx).pop(); // Tutup BottomSheet
              _confirmDeleteTransaction(transaction.id);
            },
          ),
        ],
      );
    },
  );
}


void _confirmDeleteTransaction(String transactionId) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Hapus Transaksi'),
      content: Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop(); // Tutup dialog tanpa menghapus
          },
          child: Text('Batal'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop(); // Tutup dialog
            deleteTransaction(transactionId); // Panggil fungsi yang benar
          },
          child: Text('Hapus', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}





void _startEditTransaction(Transaction transaction) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddTransaction(
        existingTransaction: transaction,
        addTransaction: (title, amount, date, imageUrl) async {
          // Ambil URL gambar lama dari Firestore
          final docRef = firestore.FirebaseFirestore.instance.collection('transactions').doc(transaction.id);
          final docSnapshot = await docRef.get();
          final oldImageUrl = docSnapshot.data()?['imageUrl'];

          // Hapus gambar lama jika ada
          if (oldImageUrl != null && oldImageUrl.isNotEmpty && oldImageUrl != imageUrl) {
            final storageRef = FirebaseStorage.instance.refFromURL(oldImageUrl);
            await storageRef.delete();
            print('Gambar lama berhasil dihapus.');
          }

          // Perbarui dokumen dengan data baru
          await docRef.update({
            'title': title,
            'amount': amount,
            'date': date.toIso8601String(),
            'imageUrl': imageUrl,
          });

          setState(() {
            final index = _transactions.indexWhere((tx) => tx.id == transaction.id);
            _transactions[index] = Transaction(
              id: transaction.id,
              title: title,
              amount: amount,
              date: date,
              imageUrl: imageUrl,
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transaksi berhasil diperbarui!')),
          );
        },
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Catatan Keuangan Pribadi'),
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Riwayat'),
              Tab(text: 'Laporan'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _startAddTransaction(context),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _transactions.isEmpty
                ? Center(child: Text('Belum ada transaksi!'))
                : ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (ctx, index) {
                      return Card(
                        child: ListTile(
                          title: Text(_transactions[index].title),
                          subtitle: Text('Rp ${_transactions[index].amount.toStringAsFixed(2)}'),
                          trailing: Text(
                            '${_transactions[index].date.day}/${_transactions[index].date.month}/${_transactions[index].date.year}',
                          ),
                          onTap: () => _showTransactionOptions(_transactions[index]),
                        ),
                      );
                    },
                  ),
            _transactions.isEmpty
                ? Center(child: Text('Tidak ada data untuk ditampilkan'))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _calculateCategorySummary().length,
                      itemBuilder: (ctx, index) {
                        final categorySummary = _calculateCategorySummary()[index];
                        return Card(
                          color: Colors.blue[100],
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  categorySummary['category'],
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Rp ${categorySummary['amount'].toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 2) {
              _navigateToSettings(); 
            } else {
              _onBottomNavigationTapped(index);
            }
          },
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Laporan'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _calculateCategorySummary() {
    final categories = <String>['Belanja', 'Transportasi', 'Makanan', 'Lain-lain'];
    final summary = categories.map((category) {
      final totalAmount = _transactions
          .where((tx) => tx.title.contains(category))
          .fold(0.0, (sum, item) => sum + item.amount);
      return {'category': category, 'amount': totalAmount};
    }).toList();
    return summary;
  }
}
