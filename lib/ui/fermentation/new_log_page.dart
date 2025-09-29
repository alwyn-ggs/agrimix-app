import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fermentation_log.dart';
import '../../models/recipe.dart';
import '../../repositories/fermentation_repo.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../recipe/list_page.dart';

class NewLogPage extends StatefulWidget {
  const NewLogPage({super.key});

  @override
  State<NewLogPage> createState() => _NewLogPageState();
}

class _NewLogPageState extends State<NewLogPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  FermentationMethod _method = FermentationMethod.ffj;
  DateTime _startAt = DateTime.now();
  bool _alerts = true;
  List<FermentationStage> _stages = const <FermentationStage>[];
  Recipe? _selectedRecipe;
  List<FermentationIngredient> _ingredients = const <FermentationIngredient>[];

  @override
  void initState() {
    super.initState();
    _stages = _defaultStages(_method);
  }

  @override
  Widget build(BuildContext context) {
    // Prefill from arguments if provided
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _selectedRecipe == null) {
      final recipe = args['recipe'] as Recipe?;
      if (recipe != null) {
        _selectedRecipe = recipe;
        _title.text = recipe.name.isNotEmpty ? 'Fermentation - ${recipe.name}' : 'New Fermentation';
        _method = recipe.method == RecipeMethod.ffj ? FermentationMethod.ffj : FermentationMethod.fpj;
        _stages = _defaultStages(_method);
        _ingredients = recipe.ingredients.map((ing) => 
          FermentationIngredient(name: ing.name, amount: ing.amount, unit: ing.unit)
        ).toList();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Fermentation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _title,
                        decoration: const InputDecoration(
                          labelText: 'Fermentation Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Method Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fermentation Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<FermentationMethod>(
                              title: const Text('FFJ'),
                              subtitle: const Text('Fermented Fruit Juice'),
                              value: FermentationMethod.ffj,
                              groupValue: _method,
                              onChanged: (v) => setState(() {
                                _method = v ?? FermentationMethod.ffj;
                                _stages = _defaultStages(_method);
                              }),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<FermentationMethod>(
                              title: const Text('FPJ'),
                              subtitle: const Text('Fermented Plant Juice'),
                              value: FermentationMethod.fpj,
                              groupValue: _method,
                              onChanged: (v) => setState(() {
                                _method = v ?? FermentationMethod.fpj;
                                _stages = _defaultStages(_method);
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recipe Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Link Recipe (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(_selectedRecipe?.name ?? 'No recipe selected'),
                        subtitle: Text(_selectedRecipe?.description ?? 'Tap to select a recipe'),
                        trailing: _selectedRecipe != null 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _selectedRecipe = null),
                            )
                          : const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          final recipe = await Navigator.push<Recipe>(
                            context,
                            MaterialPageRoute(builder: (context) => const RecipeListPage()),
                          );
                          if (recipe != null) {
                            setState(() {
                              _selectedRecipe = recipe;
                              _ingredients = recipe.ingredients.map((ing) => 
                                FermentationIngredient(
                                  name: ing.name,
                                  amount: ing.amount,
                                  unit: ing.unit,
                                )
                              ).toList();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Start Date & Time
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date & Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _startAt,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _startAt = DateTime(
                                    picked.year, 
                                    picked.month, 
                                    picked.day, 
                                    _startAt.hour, 
                                    _startAt.minute
                                  ));
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text('${_startAt.year}-${_startAt.month.toString().padLeft(2, '0')}-${_startAt.day.toString().padLeft(2, '0')}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context, 
                                  initialTime: TimeOfDay.fromDateTime(_startAt)
                                );
                                if (picked != null) {
                                  setState(() => _startAt = DateTime(
                                    _startAt.year, 
                                    _startAt.month, 
                                    _startAt.day, 
                                    picked.hour, 
                                    picked.minute
                                  ));
                                }
                              },
                              icon: const Icon(Icons.access_time),
                              label: Text('${_startAt.hour.toString().padLeft(2, '0')}:${_startAt.minute.toString().padLeft(2, '0')}'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Alerts Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Enable Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text('Get notified for each fermentation stage', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _alerts, 
                        onChanged: (v) => setState(() => _alerts = v)
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stages
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Fermentation Stages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              final edited = await _editStageDialog(context, const FermentationStage(day: 1, label: 'New Stage', action: 'Do something'));
                              if (edited != null) setState(() => _stages = [..._stages, edited]);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Stage'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap on a stage to edit it', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      ..._stages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stage = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: Text('${stage.day}', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold)),
                            ),
                            title: Text(stage.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(stage.action),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => setState(() => _stages = [..._stages]..removeAt(index)),
                            ),
                            onTap: () async {
                              final edited = await _editStageDialog(context, stage);
                              if (edited != null) setState(() => _stages[index] = edited);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notes,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Add any notes about this fermentation...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: () => _save(context),
                  icon: const Icon(Icons.add_circle),
                  label: const Text('Create Fermentation Log', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FermentationStage> _defaultStages(FermentationMethod m) {
    if (m == FermentationMethod.ffj) {
      return const [
        FermentationStage(day: 0, label: 'Day 1', action: 'Mix ingredients'),
        FermentationStage(day: 2, label: 'Day 3', action: 'Stir mixture'),
        FermentationStage(day: 6, label: 'Day 7', action: 'Strain and bottle'),
      ];
    }
    return const [
      FermentationStage(day: 0, label: 'Day 1', action: 'Mix plant tips and sugar'),
      FermentationStage(day: 2, label: 'Day 3', action: 'Stir and check aroma'),
      FermentationStage(day: 6, label: 'Day 7', action: 'Strain and store'),
    ];
  }

  Future<FermentationStage?> _editStageDialog(BuildContext context, FermentationStage stage) async {
    final dayCtrl = TextEditingController(text: stage.day.toString());
    final labelCtrl = TextEditingController(text: stage.label);
    final actionCtrl = TextEditingController(text: stage.action);
    return showDialog<FermentationStage>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Stage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: dayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Day')),
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
            TextField(controller: actionCtrl, decoration: const InputDecoration(labelText: 'Action')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final d = int.tryParse(dayCtrl.text.trim()) ?? stage.day;
              Navigator.pop(context, FermentationStage(day: d, label: labelCtrl.text.trim(), action: actionCtrl.text.trim()));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final repo = context.read<FermentationRepo>();
      final uid = context.read<AuthProvider>().currentUser?.uid ?? '';
      
      final log = FermentationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerUid: uid,
        recipeId: _selectedRecipe?.id,
        title: _title.text.trim(),
        method: _method,
        ingredients: _ingredients,
        startAt: _startAt,
        stages: _stages,
        currentStage: 0,
        status: FermentationStatus.active,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        photos: const <String>[],
        alertsEnabled: _alerts,
        createdAt: DateTime.now(),
      );
      
      await repo.createFermentationLog(log);
      
      if (_alerts) {
        final notifier = context.read<NotificationService>();
        await notifier.scheduleFermentationNotifications(
          log.id, 
          log.title, 
          _stages.map((s) => s.toMap()).toList(), 
          _startAt
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fermentation log created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating fermentation log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}