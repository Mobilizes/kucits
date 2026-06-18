import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/cat.dart';
import '../models/cat_post.dart';
import '../services/cat_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../widgets/post_card.dart';

class CatDetailScreen extends StatefulWidget {
  final String catId;

  const CatDetailScreen({super.key, required this.catId});

  @override
  State<CatDetailScreen> createState() => _CatDetailScreenState();
}

class _CatDetailScreenState extends State<CatDetailScreen> {
  Cat? _cat;
  bool _loadingCat = true;
  bool _isAdmin = false;
  bool _loadingAdmin = true;
  bool _sortByPopularity = false;

  @override
  void initState() {
    super.initState();
    _loadCatData();
    _checkAdminStatus();
  }

  Future<void> _loadCatData() async {
    try {
      final catService = Provider.of<CatService>(context, listen: false);
      final cat = await catService.getCat(widget.catId);
      if (mounted) {
        setState(() {
          _cat = cat;
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

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final userService = Provider.of<UserService>(context, listen: false);
        final profile = await userService.getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _isAdmin = profile?.isAdmin ?? false;
            _loadingAdmin = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _loadingAdmin = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingAdmin = false;
        });
      }
    }
  }

  Future<void> _deleteCatPrompt(Cat cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Cat Profile'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${cat.name}? This cat profile will be removed from the active database. '
          'Existing posts tagging this cat will be orphaned (the posts will remain, but the tag won\'t be interactive).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final catService = Provider.of<CatService>(context, listen: false);
      final success = await catService.deleteCat(cat.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cat.name} profile deleted.')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not delete cat profile.')),
        );
      }
    }
  }

  Widget _buildAppBarIcon({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final postService = Provider.of<PostService>(context);

    if (_loadingCat) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_cat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cat Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text(
                  'Cat Profile Not Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This cat profile may have been deleted, adopted, or deceased, and is no longer in the active campus database.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final cat = _cat!;
    final hasImage = cat.iconUrl.isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header / App Bar with Cat Avatar banner
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: Navigator.canPop(context)
                ? Container(
                    margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  )
                : null,
            actions: !_loadingAdmin && _isAdmin
                ? [
                    _buildAppBarIcon(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit Cat details',
                      onPressed: () => context.push('/cats/edit/${cat.id}').then((_) => _loadCatData()),
                    ),
                    _buildAppBarIcon(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete Cat',
                      onPressed: () => _deleteCatPrompt(cat),
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                cat.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1.5))],
                ),
              ),
              background: Container(
                color: cs.surfaceContainerHighest,
                child: hasImage
                    ? Image.network(
                        cat.iconUrl,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          cat.name.isNotEmpty ? cat.name[0].toUpperCase() : 'C',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Details / Bio info section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: cs.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.home_outlined, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.department,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.healing_outlined, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cat.isNeutered ? Colors.teal.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat.isNeutered ? 'Neutered / Spayed' : 'Intact',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: cat.isNeutered ? Colors.teal.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sighting Feed Sort / Header
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, thickness: 1, color: cs.outlineVariant),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Tagged Sightings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      ChoiceChip(
                        label: const Text('Latest', style: TextStyle(fontSize: 11)),
                        selected: !_sortByPopularity,
                        onSelected: (_) => setState(() => _sortByPopularity = false),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Popular', style: TextStyle(fontSize: 11)),
                        selected: _sortByPopularity,
                        onSelected: (_) => setState(() => _sortByPopularity = true),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Posts Feed List for Cat
          StreamBuilder<List<CatPost>>(
            stream: postService.streamPostsForCat(cat.id, sortByPopularity: _sortByPopularity),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error loading sightings: ${snapshot.error}',
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No sightings tagged yet.',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return PostCard(post: post);
                  },
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
