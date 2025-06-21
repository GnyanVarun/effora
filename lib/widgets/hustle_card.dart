import 'package:flutter/material.dart';
import 'package:effora/models/hustle_model.dart';

class HustleCard extends StatelessWidget {
  final Hustle hustle;

  const HustleCard({required this.hustle, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(hustle.title),
        subtitle: Text(hustle.description),
        trailing: Text(
          '₹${(hustle.totalEarnings ?? 0.0).toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
