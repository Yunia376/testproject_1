class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String? imageUrl; // Properti untuk URL gambar

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    this.imageUrl,
  });
}
