import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';

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
  final TextEditingController typeController = TextEditingController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController phController = TextEditingController();
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController shelfController = TextEditingController();
  final TextEditingController storageController = TextEditingController();
  final TextEditingController microbeController = TextEditingController();
  final TextEditingController stockController = TextEditingController();

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
  Future<String?> uploadSelectedImage() async {
    if (_selectedImage == null) return null;
    final storageService = Provider.of<StorageService>(context, listen: false);

    setState(() => _isUploadingImage = true);
    try {
      return await storageService.uploadImage(_selectedImage!);
    } finally {
      setState(() => _isUploadingImage = false);
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
  Future<void> addIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    final uploadedUrl = await uploadSelectedImage();
    final extraUrls = await uploadExtraImages();

    await ingredients.add({
      'name': nameController.text,
      'type': typeController.text,
      'origin': originController.text,
      'supplier': supplierController.text,
      'ph_level': phController.text,
      'sugar_content': sugarController.text,
      'primary_role': roleController.text,
      'recommended_dosage': dosageController.text,
      'shelf_life': shelfController.text,
      'storage_condition': storageController.text,
      'preferred_microbe': microbeController.text,
      'stock_quantity': stockController.text,
      'imageUrl': uploadedUrl ?? '',
      'extraImages': extraUrls,
      'created_at': FieldValue.serverTimestamp(),
    });

    clearForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ingredient added successfully!')),
    );
  }

  // Clear inputs
  void clearForm() {
    nameController.clear();
    typeController.clear();
    originController.clear();
    supplierController.clear();
    phController.clear();
    sugarController.clear();
    roleController.clear();
    dosageController.clear();
    shelfController.clear();
    storageController.clear();
    microbeController.clear();
    stockController.clear();
    _selectedImage = null;
    _uploadedImageUrl = null;
    _extraImages.clear();
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
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField(nameController, 'Ingredient Name'),
                    buildTextField(typeController, 'Type'),
                    buildTextField(originController, 'Origin'),
                    buildTextField(supplierController, 'Supplier'),
                    buildTextField(phController, 'pH Level'),
                    buildTextField(sugarController, 'Sugar Content (°Brix)'),
                    buildTextField(roleController, 'Primary Role'),
                    buildTextField(dosageController, 'Recommended Dosage'),
                    buildTextField(shelfController, 'Shelf Life'),
                    buildTextField(storageController, 'Storage Condition'),
                    buildTextField(microbeController, 'Preferred Microbe'),
                    buildTextField(stockController, 'Stock Quantity'),
                    const SizedBox(height: 12),

                    _selectedImage != null
                        ? Image.file(_selectedImage!, height: 120)
                        : (_uploadedImageUrl != null &&
                                _uploadedImageUrl!.isNotEmpty)
                            ? Image.network(_uploadedImageUrl!, height: 120)
                            : const Text("No image selected"),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await pickImage(ImageSource.gallery);
                            setStateDialog(() {});
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text("Gallery"),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await pickImage(ImageSource.camera);
                            setStateDialog(() {});
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Camera"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Add extra images button
                    OutlinedButton.icon(
                      onPressed: () async {
                        await pickExtraImages();
                        setStateDialog(() {});
                      },
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text("Add Extra Images"),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await addIngredient();
                  Navigator.pop(context);
                },
                child: const Text('Add'),
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
        stream: ingredients.orderBy('created_at', descending: true).snapshots(),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // ✅ Two cards per row
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72, // ✅ Show ~6 items before scrolling
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final ingredient = data[index];
              final imageUrl = ingredient['imageUrl'] ?? '';
              final extraImages =
                  List<String>.from(ingredient['extraImages'] ?? []);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ✅ Ingredient Main Image (Smaller but still clear)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 110, // ✅ Smaller image for compact UI
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            )
                          : Container(
                              height: 110,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                    ),

                    // ✅ Ingredient Name
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        ingredient['name'] ?? "Unknown Ingredient",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                                    ingredientName: ingredient['name'],
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
                                  ingredient['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow("Type", ingredient['type']),
                                      _buildInfoRow(
                                          "Origin", ingredient['origin']),
                                      _buildInfoRow(
                                          "Supplier", ingredient['supplier']),
                                      _buildInfoRow(
                                          "pH Level", ingredient['ph_level']),
                                      _buildInfoRow("Sugar Content",
                                          ingredient['sugar_content']),
                                      _buildInfoRow("Primary Role",
                                          ingredient['primary_role']),
                                      _buildInfoRow("Dosage",
                                          ingredient['recommended_dosage']),
                                      _buildInfoRow("Shelf Life",
                                          ingredient['shelf_life']),
                                      _buildInfoRow("Storage",
                                          ingredient['storage_condition']),
                                      _buildInfoRow("Preferred Microbe",
                                          ingredient['preferred_microbe']),
                                      _buildInfoRow("Stock",
                                          ingredient['stock_quantity']),
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
