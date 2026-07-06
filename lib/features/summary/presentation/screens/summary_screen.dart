import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final String tableId;
  const SummaryScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: const Center(child: Text('Summary - coming soon')),
    );
  }
}
