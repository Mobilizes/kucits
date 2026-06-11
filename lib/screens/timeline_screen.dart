import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/cat_post.dart';
import '../widgets/compose_box.dart';
import '../widgets/post_card.dart';
import 'compose_screen.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

import '../app/theme_provider.dart';

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
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final postService = Provider.of<PostService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
            icon: Icon(currentUser != null && !currentUser.isAnonymous ? Icons.person : Icons.login),
            tooltip: currentUser != null && !currentUser.isAnonymous ? 'Profile' : 'Log in',
            onPressed: () {
              if (currentUser != null && !currentUser.isAnonymous) {
                context.go('/profile');
              } else {
                context.push('/login');
              }
            },
          ),
        ),
        title: const Text(
          'KucITS 🐱',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final auth = Provider.of<AuthService>(context, listen: false);
                await auth.signOut();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Signed out successfully.')),
                );
                if (mounted) {
                  setState(() {}); // Rebuild header state
                }
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
              // Wait short duration to simulate refresh. StreamBuilder will auto-fetch latest anyway.
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
