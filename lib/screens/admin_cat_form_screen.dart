import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import 'package:image_cropper/image_cropper.dart';

class AdminCatFormScreen extends StatefulWidget {
  final String? catId; // Null if adding a new cat

  const AdminCatFormScreen({super.key, this.catId});

  @override
  State<AdminCatFormScreen> createState() => _AdminCatFormScreenState();
}

class _AdminCatFormScreenState extends State<AdminCatFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedFaculty;
  String? _selectedDepartment;
  bool _isNeutered = false;
  File? _imageFile;
  String _existingIconUrl = '';
  DateTime _existingCreatedAt = DateTime.now();

  bool _loadingCat = false;
  bool _submitting = false;

  bool _isAdmin = false;
  bool _loadingAdminCheck = true;

  final ImagePicker _picker = ImagePicker();

  final Map<String, List<String>> _faculties = {
    'FSAD': [
      'Fisika',
      'Kimia',
      'Matematika',
      'Biologi',
      'Statistika',
      'Aktuaria',
    ],
    'FTIRS': [
      'Teknik Mesin',
      'Teknik Kimia',
      'Teknik Fisika',
      'Rekayasa Keselamatan Proses',
      'Teknik Industri',
      'Teknik Material dan Metalurgi',
      'Teknik Pangan',
    ],
    'FTK': [
      'Teknik Perkapalan',
      'Teknik Sistem Perkapalan',
      'Teknik Kelautan',
      'Teknik Transportasi Laut',
      'Teknik Lepas Pantai',
    ],
    'FTSPK': [
      'Teknik Sipil',
      'Arsitektur',
      'Teknik Lingkungan',
      'Teknik Geomatika',
      'Perencanaan Wilayah Kota',
      'Teknik Geofisika',
      'Teknik Pertambangan',
    ],
    'FTEIC': [
      'Teknik Elektro',
      'Teknik Informatika',
      'Sistem Informasi',
      'Teknik Komputer',
      'Teknik Biomedik',
      'Teknologi Informasi',
      'Teknik Telekomunikasi',
    ],
    'FDKBD': [
      'Desain Produk',
      'Desain Interior',
      'Desain Komunikasi Visual',
      'Manajemen Bisnis',
      'Studi Pembangunan',
    ],
    'FV': [
      'Teknik Infrastruktur Sipil',
      'Teknik Mesin Industri',
      'Teknik Elektro Otomasi',
      'Teknik Kimia Industri',
      'Teknik Instrumentasi',
      'Statistika Bisnis',
    ],
    'FKK': ['Teknologi Kedokteran', 'Kedokteran'],
  };

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    if (widget.catId != null) {
      _loadCatData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final userService = Provider.of<UserService>(context, listen: false);
        final profile = await userService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _isAdmin = profile?.isAdmin ?? false;
            _loadingAdminCheck = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _loadingAdminCheck = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAdminCheck = false;
        });
      }
    }
  }

  Future<void> _loadCatData() async {
    setState(() {
      _loadingCat = true;
    });
    try {
      final catService = Provider.of<CatService>(context, listen: false);
      final cat = await catService.getCat(widget.catId!);
      if (cat != null && mounted) {
        setState(() {
          _nameController.text = cat.name;
          _isNeutered = cat.isNeutered;
          _existingIconUrl = cat.iconUrl;
          _existingCreatedAt = cat.createdAt;

          // Reverse lookup the faculty for the cat's department
          for (var faculty in _faculties.keys) {
            if (_faculties[faculty]!.contains(cat.department)) {
              _selectedFaculty = faculty;
              _selectedDepartment = cat.department;
              break;
            }
          }
          _loadingCat = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingCat = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final cropped = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Cat Photo',
              toolbarColor: colorScheme.surfaceContainerLow,
              toolbarWidgetColor: colorScheme.onSurface,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(
              title: 'Crop Cat Photo',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
            ),
          ],
        );

        if (mounted) {
          setState(() {
            if (cropped != null) {
              _imageFile = File(cropped.path);
            } else {
              _imageFile = File(image.path); // Fallback to original
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final catService = Provider.of<CatService>(context, listen: false);
      final storageService = Provider.of<StorageService>(
        context,
        listen: false,
      );

      final isEditing = widget.catId != null;
      final catId = isEditing
          ? widget.catId!
          : FirebaseFirestore.instance.collection('cats').doc().id;

      String iconUrl = _existingIconUrl;
      if (_imageFile != null) {
        final uploadedUrl = await storageService.uploadCatIcon(
          catId,
          _imageFile!,
        );
        if (uploadedUrl != null) {
          iconUrl = uploadedUrl;
        }
      }

      final cat = Cat(
        id: catId,
        name: _nameController.text.trim(),
        department: _selectedDepartment!,
        iconUrl: iconUrl,
        isNeutered: _isNeutered,
        createdAt: isEditing ? _existingCreatedAt : DateTime.now(),
      );

      final success = await catService.addCat(cat);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cat profile ${isEditing ? "updated" : "created"} successfully.',
              ),
            ),
          );
          context.pop();
        } else {
          throw Exception('Failed to write to database.');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving cat: $e')));
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  List<String> get _departments {
    if (_selectedFaculty == null) return [];
    return _faculties[_selectedFaculty] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEditing = widget.catId != null;

    if (_loadingAdminCheck) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Security Gate
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 64, color: cs.error),
                const SizedBox(height: 16),
                const Text(
                  'Permission Denied',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only registered campus administrators are allowed to create or edit cat database records.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadingCat) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing ? 'Edit Cat Profile' : 'Add New Cat',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cat Avatar Picker Box
                  Center(child: _buildImagePickerWidget(cs)),
                  const SizedBox(height: 24),

                  // Cat Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Cat Name',
                      prefixIcon: Icon(Icons.pets),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Faculty Dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedFaculty,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      prefixIcon: Icon(Icons.school_outlined),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select Faculty'),
                    items: _faculties.keys.map((faculty) {
                      return DropdownMenuItem<String>(
                        value: faculty,
                        child: Text(faculty, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedFaculty = val;
                        _selectedDepartment = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Department Dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.domain_outlined),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select Department'),
                    disabledHint: const Text('Select Faculty first'),
                    items: _selectedFaculty == null
                        ? null
                        : _departments.map((dept) {
                            return DropdownMenuItem<String>(
                              value: dept,
                              child: Text(
                                dept,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                    onChanged: _selectedFaculty == null
                        ? null
                        : (val) {
                            setState(() {
                              _selectedDepartment = val;
                            });
                          },
                  ),
                  const SizedBox(height: 20),

                  // Neutered Switch Toggle
                  SwitchListTile(
                    title: const Text(
                      'Spayed / Neutered',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Has this cat completed sterilization?',
                    ),
                    value: _isNeutered,
                    secondary: Icon(Icons.healing_outlined, color: cs.primary),
                    onChanged: (val) {
                      setState(() {
                        _isNeutered = val;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      isEditing ? 'Update Cat Profile' : 'Create Cat Profile',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_submitting)
          Container(
            color: Colors.black45,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildImagePickerWidget(ColorScheme cs) {
    final double radius = 54;
    final bool hasNewImage = _imageFile != null;
    final bool hasExistingImage = _existingIconUrl.isNotEmpty;

    ImageProvider? imageProvider;
    if (hasNewImage) {
      imageProvider = FileImage(_imageFile!);
    } else if (hasExistingImage) {
      imageProvider = NetworkImage(_existingIconUrl);
    }

    return GestureDetector(
      onTap: _submitting ? null : _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: cs.primaryContainer,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    Icons.add_a_photo_outlined,
                    size: 36,
                    color: cs.onPrimaryContainer,
                  )
                : null,
          ),
          if (imageProvider != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
