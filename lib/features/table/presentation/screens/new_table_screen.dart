import 'package:flutter/material.dart';

class NewTableScreen extends StatelessWidget {
  const NewTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Table')),
      body: const Center(child: Text('New Table - coming soon')),
    );
  }
}
