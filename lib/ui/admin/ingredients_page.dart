import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../models/nutrient_profile.dart';
import 'nutrient_profile_form.dart';

class IngredientsPage extends StatefulWidget {
  const IngredientsPage({super.key});

  @override
  State<IngredientsPage> createState() => _IngredientsPageState();
}

class _IngredientsPageState extends State<IngredientsPage> {
  final CollectionReference ingredients =
      FirebaseFirestore.instance.collection('ingredients');

  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  // Nutrient profile
  NutrientProfile? _nutrientProfile;

  File? _selectedImage;
  String? _uploadedImageUrl;
  final List<File> _extraImages = [];
  final List<String> _uploadedExtraImageUrls = [];
  bool _isUploadingImage = false;

  // Pick single image
  Future<void> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  // Pick multiple extra images
  Future<void> pickExtraImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage(imageQuality: 80);

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _extraImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick extra images: $e")),
      );
    }
  }

  // Upload single image
  Future<String?> uploadSelectedImage({VoidCallback? onStateChange}) async {
    if (_selectedImage == null) return null;
    final storageService = Provider.of<StorageService>(context, listen: false);

    setState(() => _isUploadingImage = true);
    onStateChange?.call();
    try {
      return await storageService.uploadImage(_selectedImage!);
    } finally {
      setState(() => _isUploadingImage = false);
      onStateChange?.call();
    }
  }

  // Upload extra images
  Future<List<String>> uploadExtraImages() async {
    if (_extraImages.isEmpty) return [];
    final storageService = Provider.of<StorageService>(context, listen: false);
    List<String> urls = [];

    for (File img in _extraImages) {
      final url = await storageService.uploadImage(img);
      urls.add(url);
    }
    return urls;
  }

  // Add ingredient
  Future<void> addIngredient({VoidCallback? onStateChange}) async {
    if (!_formKey.currentState!.validate()) return;

    final uploadedUrl = await uploadSelectedImage(onStateChange: onStateChange);
    final extraUrls = await uploadExtraImages();

    // Store the uploaded image URL for immediate display
    if (uploadedUrl != null) {
      _uploadedImageUrl = uploadedUrl;
    }

    await ingredients.add({
      'name': nameController.text,
      'category': categoryController.text, // FFJ or FPJ
      'description': descriptionController.text,
      'nutrientProfile': _nutrientProfile?.toMap(), // Include nutrient profile
      'imageUrl': uploadedUrl ?? '',
      'extraImages': extraUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Don't clear the form immediately - let user see the result
    // clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingredient added successfully!')),
    );
  }

  // Clear inputs
  void clearForm() {
    nameController.clear();
    categoryController.clear();
    descriptionController.clear();
    _selectedImage = null;
    _uploadedImageUrl = null;
    _extraImages.clear();
    _nutrientProfile = null;
    _uploadedExtraImageUrls.clear();
  }

  // Ingredient dialog
  void showIngredientDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Add Ingredient'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(nameController, 'Ingredient Name'),
                    buildCategoryDropdown(),
                    buildTextField(descriptionController, 'Description'),
                    
                    const SizedBox(height: 16),
                    
                    // Nutrient Profile Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Nutrient Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_nutrientProfile != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Configured',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _nutrientProfile == null 
                                ? 'No nutrient profile configured'
                                : 'Nutrient profile is configured for ${categoryController.text.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openNutrientProfileForm(),
                              icon: const Icon(Icons.add),
                              label: Text(_nutrientProfile == null ? 'Add Nutrient Profile' : 'Edit Nutrient Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Show selected image, uploaded image, or placeholder
                    _selectedImage != null
                        ? Stack(
                            children: [
                              Image.file(_selectedImage!, 
                                height: 120, 
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              if (_isUploadingImage)
                                Container(
                                  height: 120,
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                            ? Image.network(
                                _uploadedImageUrl!, 
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                height: 120,
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "No image selected",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                    const SizedBox(height: 10),

                    // Responsive button layout to prevent overflow
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWideScreen = constraints.maxWidth > 400;
                        return isWideScreen
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _buildImageButtons(setStateDialog),
                              )
                            : Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: _buildImageButtons(setStateDialog),
                              );
                      },
                    ),
                    const SizedBox(height: 15),

                    // Add extra images button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploadingImage ? null : () async {
                          await pickExtraImages();
                          setStateDialog(() {});
                        },
                        icon: const Icon(Icons.add_photo_alternate, size: 18),
                        label: const Text("Add Extra Images", style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    // Preview extra images
                    if (_extraImages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _extraImages
                            .map((file) => Image.file(file,
                                height: 80, width: 80, fit: BoxFit.cover))
                            .toList(),
                      ),
                  ],
                ),
              ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isUploadingImage ? null : () async {
                  await addIngredient(onStateChange: () => setStateDialog(() {}));
                  clearForm(); // Clear form after successful save
                  Navigator.pop(context);
                },
                child: _isUploadingImage 
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Uploading...'),
                        ],
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build text field
  Widget buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  // Build category dropdown
  Widget buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField<String>(
        value: categoryController.text.isEmpty ? null : categoryController.text,
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
        ),
        isExpanded: true, // Prevent overflow by expanding dropdown
        items: const [
          DropdownMenuItem(
            value: 'FFJ', 
            child: Text(
              'FFJ (Fermented Fruit Juice)',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          DropdownMenuItem(
            value: 'FPJ', 
            child: Text(
              'FPJ (Fermented Plant Juice)',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        onChanged: (value) {
          categoryController.text = value ?? '';
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select a category' : null,
      ),
    );
  }

  // Build image buttons for responsive layout
  List<Widget> _buildImageButtons(void Function(void Function()) setStateDialog) {
    return [
      OutlinedButton.icon(
        onPressed: _isUploadingImage ? null : () async {
          await pickImage(ImageSource.gallery);
          setStateDialog(() {});
        },
        icon: const Icon(Icons.photo, size: 18),
        label: const Text("Gallery", style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      OutlinedButton.icon(
        onPressed: _isUploadingImage ? null : () async {
          await pickImage(ImageSource.camera);
          setStateDialog(() {});
        },
        icon: const Icon(Icons.camera_alt, size: 18),
        label: const Text("Camera", style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      if (_selectedImage != null || _uploadedImageUrl != null)
        OutlinedButton.icon(
          onPressed: _isUploadingImage ? null : () {
            setState(() {
              _selectedImage = null;
              _uploadedImageUrl = null;
            });
            setStateDialog(() {});
          },
          icon: const Icon(Icons.clear, size: 18),
          label: const Text("Clear", style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
    ];
  }

  // Open nutrient profile form
  void _openNutrientProfileForm() {
    if (categoryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select ingredient category (FFJ or FPJ) first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NutrientProfileForm(
          initialProfile: _nutrientProfile,
          ingredientType: categoryController.text,
          title: 'Nutrient Profile for ${nameController.text}',
          onSave: (profile) {
            setState(() {
              _nutrientProfile = profile;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermentation Ingredients'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showIngredientDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ingredients.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No ingredients added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first ingredient',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200, // Maximum width for each card
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75, // ✅ Slightly more vertical space to prevent overflow
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final ingredient = data[index];
              final ingredientData = (ingredient.data() as Map<String, dynamic>?) ?? {};
              final imageUrl = ingredientData['imageUrl'] ?? '';
              final extraImages =
                  List<String>.from(ingredientData['extraImages'] ?? []);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Ingredient Main Image with actions overlay
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 100, // ✅ Reduced height to prevent overflow
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  height: 100,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditIngredientDialog(
                                  context,
                                  ingredient.id,
                                  ingredientData,
                                );
                              } else if (value == 'delete') {
                                _confirmDeleteIngredient(
                                  context,
                                  ingredient.id,
                                  ingredientData['name'] ?? 'this ingredient',
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, size: 16),
                                    SizedBox(width: 6),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    SizedBox(width: 6),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ✅ Ingredient Name and Category
                    SizedBox(
                      height: 55, // Reduced height to prevent overflow
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Text(
                            ingredientData['name'] ?? "Unknown Ingredient",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (ingredientData['category'] ?? '') == 'FFJ' 
                                  ? Colors.orange.shade100 
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              ingredientData['category'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: (ingredientData['category'] ?? '') == 'FFJ' 
                                    ? Colors.orange.shade800 
                                    : Colors.green.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        ),
                      ),
                    ),

                    // ✅ Action Icons (Extra Images + Info)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.photo_library,
                              color: Colors.green, size: 22),
                          onPressed: () {
                            if (extraImages.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No extra images available for this ingredient.",
                                  ),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExtraImagesPage(
                                    images: extraImages,
                                    ingredientName: ingredientData['name'],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.info,
                              color: Colors.blue, size: 22),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  ingredientData['name'] ?? 'Unknown Ingredient',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow("Category", ingredientData['category']),
                                      _buildInfoRow("Description", ingredientData['description']),
                                      if (ingredientData['nutrientProfile'] != null) ...[
                                        const SizedBox(height: 16),
                                        const Text(
                                          "Nutrient Profile:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildNutrientInfo(ingredientData['nutrientProfile'], ingredientData['category']),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Helper widget for info rows
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  // ✅ Helper widget for nutrient info
  Widget _buildNutrientInfo(Map<String, dynamic>? nutrientProfile, String? category) {
    if (nutrientProfile == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category == 'FFJ') ...[
          _buildNutrientRow("Nitrogen (N)", nutrientProfile['nitrogen']?.toString() ?? '0'),
          _buildNutrientRow("Potassium (K)", nutrientProfile['potassium']?.toString() ?? '0'),
          _buildNutrientRow("Phosphorus (P)", nutrientProfile['phosphorus']?.toString() ?? '0'),
        ] else if (category == 'FPJ') ...[
          _buildNutrientRow("Nitrogen (N)", nutrientProfile['nitrogen']?.toString() ?? '0'),
          _buildNutrientRow("Potassium (K)", nutrientProfile['potassium']?.toString() ?? '0'),
          _buildNutrientRow("Magnesium (Mg)", nutrientProfile['magnesium']?.toString() ?? '0'),
        ],
        const SizedBox(height: 8),
        const Text(
          "Plant Benefits:",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        _buildNutrientRow("Flowering", "${(nutrientProfile['floweringPromotion'] * 100)?.toStringAsFixed(1) ?? '0'}%"),
        _buildNutrientRow("Fruiting", "${(nutrientProfile['fruitingPromotion'] * 100)?.toStringAsFixed(1) ?? '0'}%"),
        _buildNutrientRow("Root Development", "${(nutrientProfile['rootDevelopment'] * 100)?.toStringAsFixed(1) ?? '0'}%"),
        _buildNutrientRow("Leaf Growth", "${(nutrientProfile['leafGrowth'] * 100)?.toStringAsFixed(1) ?? '0'}%"),
      ],
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// =====================
// Edit & Delete handlers
// =====================

extension on _IngredientsPageState {
  void _showEditIngredientDialog(BuildContext context, String id, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final categoryCtrl = TextEditingController(text: data['category'] ?? '');
    final descCtrl = TextEditingController(text: data['description'] ?? '');
    NutrientProfile? nutrient = data['nutrientProfile'] != null
        ? NutrientProfile.fromMap(Map<String, dynamic>.from(data['nutrientProfile']))
        : null;
    File? localSelectedImage;
    String existingImageUrl = (data['imageUrl'] ?? '') as String;
    bool isUploading = false;

    Future<void> openNutrientForm(StateSetter setStateDialog) async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NutrientProfileForm(
            initialProfile: nutrient,
            ingredientType: categoryCtrl.text,
            title: 'Nutrient Profile for ${nameCtrl.text}',
            onSave: (profile) {
              setStateDialog(() {
                nutrient = profile;
              });
            },
          ),
        ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> pickNewImage() async {
            try {
              final picker = ImagePicker();
              final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (pickedFile != null) {
                setStateDialog(() {
                  localSelectedImage = File(pickedFile.path);
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to pick image: $e')),
              );
            }
          }

          Future<void> saveChanges() async {
            try {
              setStateDialog(() { isUploading = true; });

              String? imageUrlToSave = existingImageUrl;
              if (localSelectedImage != null) {
                final storageService = Provider.of<StorageService>(context, listen: false);
                imageUrlToSave = await storageService.uploadImage(localSelectedImage!);
              }

              await ingredients.doc(id).update({
                'name': nameCtrl.text,
                'category': categoryCtrl.text,
                'description': descCtrl.text,
                'nutrientProfile': nutrient?.toMap(),
                'imageUrl': imageUrlToSave,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingredient updated successfully')),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to update: $e')),
              );
            } finally {
              setStateDialog(() { isUploading = false; });
            }
          }

          return AlertDialog(
            title: const Text('Edit Ingredient'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ingredient Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: DropdownButtonFormField<String>(
                        value: categoryCtrl.text.isEmpty ? null : categoryCtrl.text,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'FFJ', child: Text('FFJ (Fermented Fruit Juice)')),
                          DropdownMenuItem(value: 'FPJ', child: Text('FPJ (Fermented Plant Juice)')),
                        ],
                        onChanged: (v) => setStateDialog(() { categoryCtrl.text = v ?? ''; }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text('Nutrient Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (nutrient != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('Configured', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => openNutrientForm(setStateDialog),
                              icon: const Icon(Icons.add),
                              label: Text(nutrient == null ? 'Add Nutrient Profile' : 'Edit Nutrient Profile'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isUploading ? null : pickNewImage,
                        icon: const Icon(Icons.photo, size: 18),
                        label: Text(localSelectedImage == null ? 'Change Image' : 'Image Selected'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : saveChanges,
                child: isUploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteIngredient(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ingredients.doc(id).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingredient deleted')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// ✅ Extra Images Viewer Page (Full Screen + Zoom + Swipe)
class ExtraImagesPage extends StatefulWidget {
  final List<String> images;
  final String ingredientName;

  const ExtraImagesPage({
    super.key,
    required this.images,
    required this.ingredientName,
  });

  @override
  State<ExtraImagesPage> createState() => _ExtraImagesPageState();
}

class _ExtraImagesPageState extends State<ExtraImagesPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("${widget.ingredientName} - Extra Images"),
        backgroundColor: Colors.black,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
