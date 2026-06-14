import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/cat_post.dart';
import '../widgets/compose_box.dart';
import '../widgets/post_card.dart';
import 'compose_screen.dart';
import '../services/post_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  void _openCompose() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    if (user == null || user.isAnonymous) {
      _promptLogin('Please log in to report a cat encounter.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const ComposeScreen(),
      ),
    );
  }

  void _promptLogin(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Login',
          onPressed: () {
            context.push('/login');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final postService = Provider.of<PostService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KucITS 🐱',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<CatPost>>(
              stream: postService.streamFeed(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading feed: ${snapshot.error}',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }

                final posts = snapshot.data ?? [];

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    itemCount: posts.length + 2,
                    itemBuilder: (_, index) {
                      if (index == 0) {
                        return ComposeBox(onTap: _openCompose);
                      }
                      if (index == 1) {
                        return Divider(
                          height: 1,
                          thickness: 1,
                          color: colorScheme.outlineVariant,
                        );
                      }
                      final post = posts[index - 2];
                      return PostCard(post: post);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        tooltip: 'New post',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
