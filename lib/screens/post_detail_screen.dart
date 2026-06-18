import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../models/cat_post.dart';
import '../models/comment.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'compose_screen.dart';
import 'user_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final CatPost post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _submittingComment = false;
  int _currentImageIndex = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        final profile = await UserService().getUserProfile(user.uid);
        if (mounted) {
          setState(() {
            _isAdmin = profile?.isAdmin ?? false;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(String postId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in with an account to comment.'),
        ),
      );
      return;
    }

    setState(() {
      _submittingComment = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final postService = Provider.of<PostService>(context, listen: false);

      final profile = await userService.getUserProfile(user.uid);
      final username = profile?.username ?? user.displayName ?? 'Anonymous';
      final avatarUrl = profile?.profilePictureUrl ?? '';

      final comment = Comment(
        id: '',
        postId: postId,
        authorId: user.uid,
        authorUsername: username,
        authorAvatarUrl: avatarUrl,
        text: text,
        timestamp: DateTime.now(),
      );

      final success = await postService.addComment(postId, comment);
      if (success) {
        _commentController.clear();
        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingComment = false;
        });
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this encounter? This cannot be undone.',
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
      final postService = Provider.of<PostService>(context, listen: false);
      final success = await postService.deletePost(postId);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to delete post.')));
      }
    }
  }

  Future<void> _deleteComment(String postId, String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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
      final postService = Provider.of<PostService>(context, listen: false);
      final success = await postService.deleteComment(postId, commentId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted successfully.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment.')),
        );
      }
    }
  }

  void _editPost(CatPost currentPost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ComposeScreen(postToEdit: currentPost),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Post Deleted')),
            body: const Center(
              child: Text('This post is no longer available.'),
            ),
          );
        }

        final postDoc =
            snapshot.data! as DocumentSnapshot<Map<String, dynamic>>;
        final currentPost = CatPost.fromSnapshot(postDoc);
        final isAuthor = currentUser?.uid == currentPost.authorId;
        final showDelete = isAuthor || _isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Encounter Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              if (isAuthor)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editPost(currentPost),
                  tooltip: 'Edit post',
                ),
              if (showDelete)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deletePost(currentPost.id),
                  tooltip: 'Delete post',
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildAuthorHeader(context, currentPost),
                    _buildImageSection(context, currentPost),
                    _buildPostContent(context, currentPost),
                    const Divider(),
                    _buildCommentsSection(context, currentPost.id),
                  ],
                ),
              ),
              _buildCommentInputSection(context, currentPost.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuthorHeader(BuildContext context, CatPost post) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileScreen(userId: post.authorId),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              backgroundImage: post.authorAvatarUrl.isNotEmpty
                  ? NetworkImage(post.authorAvatarUrl)
                  : null,
              child: post.authorAvatarUrl.isNotEmpty
                  ? null
                  : Text(
                      post.authorUsername.isEmpty
                          ? 'U'
                          : post.authorUsername[0].toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatTimestamp(post.timestamp),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, CatPost post) {
    final cs = Theme.of(context).colorScheme;
    if (post.photoUrls.isEmpty) return const SizedBox.shrink();

    if (post.photoUrls.length == 1) {
      return InteractiveViewer(
        child: Image.network(
          post.photoUrls[0],
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            color: cs.surfaceContainerHighest,
            height: 200,
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: PageView.builder(
            itemCount: post.photoUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Container(
                  color: Colors.black,
                  child: Image.network(
                    post.photoUrls[index],
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (post.photoUrls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              post.photoUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? cs.primary
                      : cs.outlineVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPostContent(BuildContext context, CatPost post) {
    final cs = Theme.of(context).colorScheme;
    final postService = Provider.of<PostService>(context, listen: false);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tagged Cats Chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: post.cats.map((cat) {
              return ActionChip(
                avatar: CircleAvatar(
                  backgroundColor: cs.secondaryContainer,
                  child: Text(
                    cat.name[0],
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
                label: Text(cat.name, style: const TextStyle(fontSize: 12)),
                backgroundColor: cs.surfaceContainerLow,
                onPressed: () {
                  context.push('/cats/${cat.id}');
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Caption
          Text(post.caption, style: const TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(height: 16),

          // Location Tag if present
          if (post.location != null) ...[
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Coordinates: ${post.location!.latitude}, ${post.location!.longitude}',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 18, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      'ITS Surabaya',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Likes / Comments interactive count bar
          Row(
            children: [
              if (currentUser != null && !currentUser.isAnonymous)
                StreamBuilder<bool>(
                  stream: postService.streamIsLiked(post.id, currentUser.uid),
                  builder: (context, likeSnapshot) {
                    final isLiked = likeSnapshot.data ?? false;
                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null,
                          ),
                          onPressed: () =>
                              postService.toggleLike(post.id, currentUser.uid),
                        ),
                        Text(
                          '${post.likes}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'You must log in to like posts.',
                            ),
                            action: SnackBarAction(
                              label: 'Login',
                              onPressed: () => context.push('/login'),
                            ),
                          ),
                        );
                      },
                    ),
                    Text('${post.likes}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 20),
              const SizedBox(width: 6),
              Text(
                '${post.comments}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, String postId) {
    final postService = Provider.of<PostService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<List<Comment>>(
      stream: postService.streamComments(postId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'No comments yet. Be the first to share your thoughts!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final isCommentAuthor = currentUser?.uid == comment.authorId;
                final showDeleteComment = isCommentAuthor || _isAdmin;

                return ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(userId: comment.authorId),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: cs.secondaryContainer,
                      radius: 16,
                      backgroundImage: comment.authorAvatarUrl.isNotEmpty
                          ? NetworkImage(comment.authorAvatarUrl)
                          : null,
                      child: comment.authorAvatarUrl.isNotEmpty
                          ? null
                          : Text(
                              comment.authorUsername.isEmpty
                                  ? 'U'
                                  : comment.authorUsername[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.onSecondaryContainer,
                              ),
                            ),
                    ),
                  ),
                  title: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(userId: comment.authorId),
                            ),
                          );
                        },
                        child: Text(
                          comment.authorUsername,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTimestamp(comment.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      comment.text,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  trailing: showDeleteComment
                      ? IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => _deleteComment(postId, comment.id),
                        )
                      : null,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInputSection(BuildContext context, String postId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (currentUser == null || currentUser.isAnonymous) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
        ),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('You must log in to comment.'),
                action: SnackBarAction(
                  label: 'Login',
                  onPressed: () => context.push('/login'),
                ),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              const Text(
                'Log in to leave a comment…',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              enabled: !_submittingComment,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          IconButton(
            icon: _submittingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.send, color: cs.primary),
            onPressed: _submittingComment ? null : () => _submitComment(postId),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
