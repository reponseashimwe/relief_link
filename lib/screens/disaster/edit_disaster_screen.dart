import 'package:flutter/material.dart';
import '../../models/disaster.dart';

class EditDisasterScreen extends StatefulWidget {
  final Disaster disaster;

  const EditDisasterScreen({
    Key? key,
    required this.disaster,
  }) : super(key: key);

  @override
  State<EditDisasterScreen> createState() => _EditDisasterScreenState();
}

class _EditDisasterScreenState extends State<EditDisasterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Disaster'),
      ),
      body: Center(
        child: Text('Edit disaster form for: ${widget.disaster.title}'),
      ),
    );
  }
} 