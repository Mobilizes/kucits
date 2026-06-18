import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/post_service.dart';
import 'post_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
    String docId,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await _db
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final postId = notification['postId'] as String? ?? '';
      final post = await PostService().getPost(postId);

      if (context.mounted) {
        Navigator.pop(context);
      }

      if (post != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This post has been deleted.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading post: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    if (currentUser == null || currentUser.isAnonymous) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 80,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in for Notifications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Guest users do not receive notifications. Create an account or sign in to receive real-time updates when others like or comment on your sightings!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In or Register'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(snapshot.data?.docs ?? []);
          docs.sort((a, b) {
            final aTime = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent notifications to show.',
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final isRead = data['isRead'] as bool? ?? false;
              final type = data['type'] as String? ?? 'like';
              final senderUsername =
                  data['senderUsername'] as String? ?? 'Someone';
              final senderAvatarUrl = data['senderAvatarUrl'] as String? ?? '';
              final body = data['body'] as String? ?? '';
              final timestamp =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              IconData iconData;
              Color iconColor;
              if (type == 'like') {
                iconData = Icons.favorite;
                iconColor = Colors.red;
              } else {
                iconData = Icons.comment;
                iconColor = cs.primary;
              }

              return ListTile(
                onTap: () => _handleNotificationTap(context, data, doc.id),
                tileColor: isRead
                    ? null
                    : cs.primaryContainer.withValues(alpha: 0.05),
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isRead
                          ? cs.surfaceContainerHighest
                          : cs.primaryContainer,
                      backgroundImage: senderAvatarUrl.isNotEmpty
                          ? NetworkImage(senderAvatarUrl)
                          : null,
                      child: senderAvatarUrl.isEmpty
                          ? Text(
                              senderUsername.isNotEmpty
                                  ? senderUsername[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: isRead
                                    ? cs.onSurfaceVariant
                                    : cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(iconData, size: 12, color: iconColor),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
                trailing: !isRead
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
