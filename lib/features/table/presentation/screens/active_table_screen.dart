import 'package:flutter/material.dart';

class ActiveTableScreen extends StatelessWidget {
  final String tableId;
  const ActiveTableScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Table')),
      body: const Center(child: Text('Active Table - coming soon')),
    );
  }
}
