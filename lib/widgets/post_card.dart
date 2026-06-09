import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../models/cat_post.dart';

class PostCard extends StatelessWidget {
  final CatPost post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          _buildPhoto(context),
          _buildCaption(),
          _buildInteractions(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cats = post.cats;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _buildAvatarStack(cats, cs),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _catNames(cats),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'by ${post.authorUsername}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            _formatTimestamp(post.timestamp),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<Cat> cats, ColorScheme cs) {
    const radius = 20.0;
    const overlap = 14.0;
    final count = cats.length.clamp(1, 2);
    final width = count == 1 ? radius * 2 : radius * 2 + overlap;

    return SizedBox(
      width: width,
      height: radius * 2,
      child: Stack(
        children: [
          // Second avatar behind (slightly offset right)
          if (cats.length > 1)
            Positioned(
              left: overlap,
              child: _avatar(cats[1], radius, cs.secondaryContainer,
                  cs.onSecondaryContainer),
            ),
          // First avatar in front
          Positioned(
            left: 0,
            child: _avatar(
                cats[0], radius, cs.primaryContainer, cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }

  Widget _avatar(Cat cat, double radius, Color bg, Color fg) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: cat.iconUrl.isEmpty
          ? Text(cat.name[0],
              style: TextStyle(fontWeight: FontWeight.bold, color: fg))
          : Image.network(cat.iconUrl),
    );
  }

  String _catNames(List<Cat> cats) {
    if (cats.length == 1) return cats[0].name;
    if (cats.length == 2) return '${cats[0].name} & ${cats[1].name}';
    return '${cats[0].name} & ${cats.length - 1} more';
  }

  Widget _buildPhoto(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      height: 200,
      color: cs.surfaceContainerHighest,
      child: Center(
          child: Icon(Icons.pets, size: 60, color: cs.onSurfaceVariant)),
    );

    if (post.photoUrls.isEmpty) return placeholder;

    return Image.network(
      post.photoUrls.first,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(post.caption),
    );
  }

  Widget _buildInteractions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 20),
            onPressed: () {},
          ),
          Text('${post.likes}', style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            onPressed: () {},
          ),
          Text('${post.comments}', style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
