import 'package:flutter/material.dart';
import '../../models/nutrient_profile.dart';
import '../../theme/theme.dart';

class NutrientProfileForm extends StatefulWidget {
  final NutrientProfile? initialProfile;
  final Function(NutrientProfile) onSave;
  final String? title;
  final String ingredientType; // 'FFJ' or 'FPJ'

  const NutrientProfileForm({
    super.key,
    this.initialProfile,
    required this.onSave,
    this.title,
    required this.ingredientType,
  });

  @override
  State<NutrientProfileForm> createState() => _NutrientProfileFormState();
}

class _NutrientProfileFormState extends State<NutrientProfileForm> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for macronutrients
  late TextEditingController _nitrogenController;
  late TextEditingController _phosphorusController;
  late TextEditingController _potassiumController;
  late TextEditingController _calciumController;
  late TextEditingController _magnesiumController;
  late TextEditingController _sulfurController;
  
  // Controllers for micronutrients
  late TextEditingController _ironController;
  late TextEditingController _manganeseController;
  late TextEditingController _zincController;
  late TextEditingController _copperController;
  late TextEditingController _boronController;
  late TextEditingController _molybdenumController;
  
  // Controllers for growth hormones
  late TextEditingController _auxinsController;
  late TextEditingController _cytokininsController;
  late TextEditingController _gibberellinsController;
  late TextEditingController _enzymesController;
  late TextEditingController _organicAcidsController;
  late TextEditingController _sugarsController;
  
  // Controllers for plant benefits (0-100%)
  late TextEditingController _floweringController;
  late TextEditingController _fruitingController;
  late TextEditingController _rootDevelopmentController;
  late TextEditingController _leafGrowthController;
  late TextEditingController _diseaseResistanceController;
  late TextEditingController _pestResistanceController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = widget.initialProfile ?? const NutrientProfile();
    
    // Macronutrients
    _nitrogenController = TextEditingController(text: profile.nitrogen.toString());
    _phosphorusController = TextEditingController(text: profile.phosphorus.toString());
    _potassiumController = TextEditingController(text: profile.potassium.toString());
    _calciumController = TextEditingController(text: profile.calcium.toString());
    _magnesiumController = TextEditingController(text: profile.magnesium.toString());
    _sulfurController = TextEditingController(text: profile.sulfur.toString());
    
    // Micronutrients
    _ironController = TextEditingController(text: profile.iron.toString());
    _manganeseController = TextEditingController(text: profile.manganese.toString());
    _zincController = TextEditingController(text: profile.zinc.toString());
    _copperController = TextEditingController(text: profile.copper.toString());
    _boronController = TextEditingController(text: profile.boron.toString());
    _molybdenumController = TextEditingController(text: profile.molybdenum.toString());
    
    // Growth hormones
    _auxinsController = TextEditingController(text: profile.auxins.toString());
    _cytokininsController = TextEditingController(text: profile.cytokinins.toString());
    _gibberellinsController = TextEditingController(text: profile.gibberellins.toString());
    _enzymesController = TextEditingController(text: profile.enzymes.toString());
    _organicAcidsController = TextEditingController(text: profile.organicAcids.toString());
    _sugarsController = TextEditingController(text: profile.sugars.toString());
    
    // Plant benefits
    _floweringController = TextEditingController(text: (profile.floweringPromotion * 100).toString());
    _fruitingController = TextEditingController(text: (profile.fruitingPromotion * 100).toString());
    _rootDevelopmentController = TextEditingController(text: (profile.rootDevelopment * 100).toString());
    _leafGrowthController = TextEditingController(text: (profile.leafGrowth * 100).toString());
    _diseaseResistanceController = TextEditingController(text: (profile.diseaseResistance * 100).toString());
    _pestResistanceController = TextEditingController(text: (profile.pestResistance * 100).toString());
  }

  @override
  void dispose() {
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _calciumController.dispose();
    _magnesiumController.dispose();
    _sulfurController.dispose();
    _ironController.dispose();
    _manganeseController.dispose();
    _zincController.dispose();
    _copperController.dispose();
    _boronController.dispose();
    _molybdenumController.dispose();
    _auxinsController.dispose();
    _cytokininsController.dispose();
    _gibberellinsController.dispose();
    _enzymesController.dispose();
    _organicAcidsController.dispose();
    _sugarsController.dispose();
    _floweringController.dispose();
    _fruitingController.dispose();
    _rootDevelopmentController.dispose();
    _leafGrowthController.dispose();
    _diseaseResistanceController.dispose();
    _pestResistanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Nutrient Profile'),
        backgroundColor: NatureColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show different nutrients based on ingredient type
              if (widget.ingredientType.toUpperCase() == 'FFJ') ...[
                _buildSectionHeader('FFJ Nutrients', Icons.science),
                _buildNutrientRow('Potassium (K)', _potassiumController, 'For fruit development and disease resistance'),
                _buildNutrientRow('Phosphorus (P)', _phosphorusController, 'For root development and flowering'),
                _buildNutrientRow('Natural Plant Hormones', _auxinsController, 'Growth hormones for plant development'),
              ] else if (widget.ingredientType.toUpperCase() == 'FPJ') ...[
                _buildSectionHeader('FPJ Nutrients', Icons.eco),
                _buildNutrientRow('Nitrogen (N)', _nitrogenController, 'For leaf growth and green color'),
                _buildNutrientRow('Potassium (K)', _potassiumController, 'For fruit development and disease resistance'),
                _buildNutrientRow('Magnesium (Mg)', _magnesiumController, 'For chlorophyll production'),
              ],
              
              const SizedBox(height: 24),
              
              // Plant Benefits Section (always show)
              _buildSectionHeader('Plant Benefits (%)', Icons.agriculture),
              _buildPercentageRow('Flowering Promotion', _floweringController, 'How much this promotes flowering'),
              _buildPercentageRow('Fruiting Promotion', _fruitingController, 'How much this promotes fruiting'),
              _buildPercentageRow('Root Development', _rootDevelopmentController, 'How much this promotes root growth'),
              _buildPercentageRow('Leaf Growth', _leafGrowthController, 'How much this promotes leaf development'),
              _buildPercentageRow('Disease Resistance', _diseaseResistanceController, 'How much this improves disease resistance'),
              _buildPercentageRow('Pest Resistance', _pestResistanceController, 'How much this improves pest resistance'),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NatureColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Nutrient Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NatureColors.primaryGreen.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NatureColors.primaryGreen.withAlpha((0.3 * 255).round())),
      ),
      child: Row(
        children: [
          Icon(icon, color: NatureColors.primaryGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: NatureColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientRow(String label, TextEditingController controller, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '0.0',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final num = double.tryParse(value);
                if (num == null) return 'Invalid number';
                if (num < 0) return 'Must be positive';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageRow(String label, TextEditingController controller, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '0',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final num = double.tryParse(value);
                      if (num == null) return 'Invalid number';
                      if (num < 0 || num > 100) return 'Must be 0-100%';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    try {
      final profile = NutrientProfile(
        // Macronutrients
        nitrogen: double.parse(_nitrogenController.text),
        phosphorus: double.parse(_phosphorusController.text),
        potassium: double.parse(_potassiumController.text),
        calcium: double.parse(_calciumController.text),
        magnesium: double.parse(_magnesiumController.text),
        sulfur: double.parse(_sulfurController.text),
        
        // Micronutrients
        iron: double.parse(_ironController.text),
        manganese: double.parse(_manganeseController.text),
        zinc: double.parse(_zincController.text),
        copper: double.parse(_copperController.text),
        boron: double.parse(_boronController.text),
        molybdenum: double.parse(_molybdenumController.text),
        
        // Growth hormones
        auxins: double.parse(_auxinsController.text),
        cytokinins: double.parse(_cytokininsController.text),
        gibberellins: double.parse(_gibberellinsController.text),
        enzymes: double.parse(_enzymesController.text),
        organicAcids: double.parse(_organicAcidsController.text),
        sugars: double.parse(_sugarsController.text),
        
        // Plant benefits (convert from percentage to decimal)
        floweringPromotion: double.parse(_floweringController.text) / 100,
        fruitingPromotion: double.parse(_fruitingController.text) / 100,
        rootDevelopment: double.parse(_rootDevelopmentController.text) / 100,
        leafGrowth: double.parse(_leafGrowthController.text) / 100,
        diseaseResistance: double.parse(_diseaseResistanceController.text) / 100,
        pestResistance: double.parse(_pestResistanceController.text) / 100,
      );

      widget.onSave(profile);
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nutrient profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
