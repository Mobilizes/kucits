import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../models/cat_post.dart';

class ComposeScreen extends StatefulWidget {
  final List<Cat> userCats;
  final void Function(CatPost post) onPost;

  const ComposeScreen({
    super.key,
    required this.userCats,
    required this.onPost,
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final List<Cat> _selectedCats = [];
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const int _maxLength = 280;

  int get _remaining => _maxLength - _captionController.text.length;
  bool get _canPost =>
      _selectedCats.isNotEmpty && _captionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showCatPicker() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.userCats.map((cat) {
                  final checked = _selectedCats.contains(cat);
                  return CheckboxListTile(
                    value: checked,
                    contentPadding: EdgeInsets.zero,
                    title: Text(cat.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(cat.breed),
                    secondary: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(cat.name[0],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ),
                    onChanged: (_) {
                      setState(() {
                        checked
                            ? _selectedCats.remove(cat)
                            : _selectedCats.add(cat);
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

  void _submit() {
    widget.onPost(
      CatPost(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cats: List.unmodifiable(_selectedCats),
        catIds: _selectedCats.map((c) => c.id).toList(),
        ownerId: 'current_user',
        ownerName: 'You',
        caption: _captionController.text.trim(),
        photoUrl: '',
        timestamp: DateTime.now(),
      ),
    );
    Navigator.pop(context);
  }

  String get _hintText {
    if (_selectedCats.isEmpty) return 'Tag some cats, then write your update…';
    final names = _selectedCats.map((c) => c.name).join(' and ');
    return 'What ${_selectedCats.length == 1 ? 'is $names' : 'are $names'} up to?';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildBody(cs)),
          _buildBottomBar(cs),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
      leadingWidth: 80,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: FilledButton(
            onPressed: _canPost ? _submit : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: const StadiumBorder(),
            ),
            child: const Text('Post',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Dropdown trigger
                InkWell(
                  onTap: _showCatPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pets, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedCats.isEmpty
                                ? 'Tag cats…'
                                : _selectedCats
                                    .map((c) => c.name)
                                    .join(', '),
                            style: TextStyle(
                              fontSize: 14,
                              color: _selectedCats.isEmpty
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Caption field
                TextField(
                  controller: _captionController,
                  focusNode: _focusNode,
                  maxLines: null,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(fontSize: 17),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: _hintText,
                    hintStyle: TextStyle(
                        fontSize: 17, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          border:
              Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.image_outlined), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.gif_box_outlined), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.poll_outlined), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.location_on_outlined), onPressed: () {}),
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
