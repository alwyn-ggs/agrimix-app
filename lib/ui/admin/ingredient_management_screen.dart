import 'package:flutter/material.dart';

class IngredientManagementScreen extends StatefulWidget {
  const IngredientManagementScreen({super.key});

  @override
  State<IngredientManagementScreen> createState() => _IngredientManagementScreenState();
}

class _IngredientManagementScreenState extends State<IngredientManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingredient Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text('Ingredient management content removed'),
      ),
    );
  }
}
