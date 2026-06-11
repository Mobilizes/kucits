import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cat.dart';
import '../models/cat_post.dart';
import '../services/cat_service.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class ComposeScreen extends StatefulWidget {
  final CatPost? postToEdit;

  const ComposeScreen({
    super.key,
    this.postToEdit,
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final List<Cat> _selectedCats = [];
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImageFiles = [];
  final List<String> _photoUrls = []; // Existing URLs if editing
  GeoPoint? _location;

  List<Cat> _allCats = [];
  bool _isLoadingCats = true;
  bool _isSubmitting = false;

  static const int _maxLength = 280;

  int get _remaining => _maxLength - _captionController.text.length;
  bool get _canPost =>
      _selectedCats.isNotEmpty &&
      _captionController.text.trim().isNotEmpty &&
      _remaining >= 0 &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadCats();
    });

    if (widget.postToEdit != null) {
      _captionController.text = widget.postToEdit!.caption;
      _selectedCats.addAll(widget.postToEdit!.cats);
      _photoUrls.addAll(widget.postToEdit!.photoUrls);
      _location = widget.postToEdit!.location;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCats() async {
    final catService = Provider.of<CatService>(context, listen: false);
    catService.streamCats().first.then((cats) {
      if (mounted) {
        setState(() {
          _allCats = cats;
          _isLoadingCats = false;
        });
      }
    });
  }

  void _showCatPicker() {
    if (_isLoadingCats) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.pets),
                SizedBox(width: 8),
                Text('Tag Cats'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: _allCats.isEmpty
                  ? const Center(child: Text('No cats found in database.'))
                  : ListView(
                      shrinkWrap: true,
                      children: _allCats.map((cat) {
                        final checked = _selectedCats.any((c) => c.id == cat.id);
                        return CheckboxListTile(
                          value: checked,
                          contentPadding: EdgeInsets.zero,
                          title: Text(cat.name,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(cat.department),
                          secondary: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Text(cat.name[0],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onPrimaryContainer)),
                          ),
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                _selectedCats.removeWhere((c) => c.id == cat.id);
                              } else {
                                if (_selectedCats.length >= 10) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Max 10 tagged cats per post')),
                                  );
                                  return;
                                }
                                _selectedCats.add(cat);
                              }
                            });
                            setDialogState(() {});
                          },
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final currentCount = _selectedImageFiles.length + _photoUrls.length;
    if (currentCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only add up to 4 photos.')),
      );
      return;
    }
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          final remaining = 4 - currentCount;
          _selectedImageFiles.addAll(
            images.take(remaining).map((x) => File(x.path)),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _toggleLocation() {
    setState(() {
      if (_location == null) {
        _location = const GeoPoint(-7.279604, 112.797274);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tagged location: ITS Surabaya')),
        );
      } else {
        _location = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location tag removed')),
        );
      }
    });
  }

  Future<void> _submit() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in with an account to post.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final postService = Provider.of<PostService>(context, listen: false);
      final storageService = Provider.of<StorageService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);

      final profile = await userService.getUserProfile(currentUser.uid);
      final username = profile?.username ?? currentUser.displayName ?? 'Anonymous';
      final avatarUrl = profile?.profilePictureUrl ?? '';

      final isEditing = widget.postToEdit != null;
      final postId = isEditing ? widget.postToEdit!.id : FirebaseFirestore.instance.collection('posts').doc().id;

      final List<String> uploadedUrls = List.from(_photoUrls);
      for (int i = 0; i < _selectedImageFiles.length; i++) {
        final file = _selectedImageFiles[i];
        final url = await storageService.uploadPostPhoto(postId, file, uploadedUrls.length);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      final post = CatPost(
        id: postId,
        cats: List.unmodifiable(_selectedCats),
        catIds: _selectedCats.map((c) => c.id).toList(),
        authorId: currentUser.uid,
        authorUsername: username,
        authorAvatarUrl: avatarUrl,
        caption: _captionController.text.trim(),
        photoUrls: uploadedUrls,
        location: _location,
        timestamp: isEditing ? widget.postToEdit!.timestamp : DateTime.now(),
        likes: isEditing ? widget.postToEdit!.likes : 0,
        comments: isEditing ? widget.postToEdit!.comments : 0,
      );

      bool success;
      if (isEditing) {
        success = await postService.updatePost(post);
      } else {
        success = await postService.createPost(post);
      }

      if (success) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to write to database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String get _hintText {
    if (_selectedCats.isEmpty) return 'Tag some cats, then write your update…';
    final names = _selectedCats.map((c) => c.name).join(' and ');
    return 'What ${_selectedCats.length == 1 ? 'is $names' : 'are $names'} up to?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(child: _buildBody(cs)),
              _buildBottomBar(cs),
            ],
          ),
        ),
        if (_isSubmitting)
          Container(
            color: Colors.black45,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  AppBar _buildAppBar() {
    final isEditing = widget.postToEdit != null;
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: Center(
        child: TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
      leadingWidth: 80,
      title: Text(isEditing ? 'Edit Post' : 'New Encounter', style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: FilledButton(
            onPressed: _canPost ? _submit : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: const StadiumBorder(),
            ),
            child: Text(isEditing ? 'Update' : 'Post',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cs.primaryContainer,
            child: Icon(Icons.person, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag cats dropdown trigger
                InkWell(
                  onTap: _isSubmitting ? null : _showCatPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pets, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedCats.isEmpty
                                ? 'Tag cats… (Required)'
                                : _selectedCats.map((c) => c.name).join(', '),
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedCats.isEmpty
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Location Indicator
                if (_location != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Chip(
                      avatar: const Icon(Icons.location_on, size: 16),
                      label: const Text('ITS Surabaya', style: TextStyle(fontSize: 12)),
                      onDeleted: _isSubmitting ? null : _toggleLocation,
                    ),
                  ),

                // Caption field
                TextField(
                  controller: _captionController,
                  focusNode: _focusNode,
                  maxLines: null,
                  enabled: !_isSubmitting,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _hintText,
                    hintStyle: TextStyle(
                        fontSize: 17, color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),

                // Image previews
                _buildImagePreviews(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviews(ColorScheme cs) {
    final totalImages = _photoUrls.length + _selectedImageFiles.length;
    if (totalImages == 0) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages,
        itemBuilder: (context, index) {
          final isExisting = index < _photoUrls.length;
          Widget imageWidget;

          if (isExisting) {
            imageWidget = Image.network(
              _photoUrls[index],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            );
          } else {
            final fileIndex = index - _photoUrls.length;
            imageWidget = Image.file(
              _selectedImageFiles[fileIndex],
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            );
          }

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageWidget,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              if (isExisting) {
                                _photoUrls.removeAt(index);
                              } else {
                                final fileIndex = index - _photoUrls.length;
                                _selectedImageFiles.removeAt(fileIndex);
                              }
                            });
                          },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    final typed = _captionController.text.length;
    final progress = (typed / _maxLength).clamp(0.0, 1.0);
    final nearLimit = _remaining < 20;
    final overLimit = _remaining < 0;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.image_outlined, color: cs.primary),
              onPressed: _isSubmitting ? null : _pickImage,
              tooltip: 'Add photo (max 4)',
            ),
            IconButton(
              icon: Icon(
                _location == null ? Icons.location_on_outlined : Icons.location_on,
                color: _location == null ? cs.onSurfaceVariant : cs.primary,
              ),
              onPressed: _isSubmitting ? null : _toggleLocation,
              tooltip: 'Tag location',
            ),
            const Spacer(),
            if (typed > 0) ...[
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  backgroundColor: cs.outlineVariant,
                  color: overLimit
                      ? cs.error
                      : nearLimit
                          ? Colors.orange
                          : cs.primary,
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 28,
                child: Text(
                  '$_remaining',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    color: overLimit
                        ? cs.error
                        : nearLimit
                            ? Colors.orange
                            : cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}
