import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String label;

  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Text(
          '$label coming soon',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
