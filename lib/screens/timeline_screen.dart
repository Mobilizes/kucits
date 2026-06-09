import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../models/cat_post.dart';
import '../widgets/compose_box.dart';
import '../widgets/post_card.dart';
import 'compose_screen.dart';
import 'profile_management_screen.dart';
import '../services/auth_service.dart';

class TimelineScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const TimelineScreen({super.key, required this.onToggleTheme});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final List<Cat> _userCats = [
    Cat(id: 'u1', name: 'Whiskers', department: 'Teknik Informatika', iconUrl: '', isNeutered: true, createdAt: DateTime.now()),
    Cat(id: 'u2', name: 'Shadow', department: 'Sistem Informasi', iconUrl: '', isNeutered: false, createdAt: DateTime.now()),
  ];

  late List<CatPost> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _seedPosts();
  }

  List<CatPost> _seedPosts() => [
    CatPost(
      id: '1',
      cats: [Cat(id: 'c1', name: 'Mochi', department: 'Sistem Informasi', iconUrl: '', isNeutered: true, createdAt: DateTime.now())],
      catIds: ['c1'],
      authorId: 'user_arya',
      authorUsername: 'Arya',
      authorAvatarUrl: '',
      caption: 'Mochi just found her favorite sunspot in the dorm! 🌞',
      photoUrls: ['https://placekittens.com/400/300'],
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      likes: 24,
      comments: 5,
    ),
    CatPost(
      id: '2',
      cats: [
        Cat(id: 'c2', name: 'Biscuit', department: 'Desain', iconUrl: '', isNeutered: false, createdAt: DateTime.now()),
        Cat(id: 'c6', name: 'Nugget', department: 'Desain', iconUrl: '', isNeutered: true, createdAt: DateTime.now()),
      ],
      catIds: ['c2', 'c6'],
      authorId: 'user_budi',
      authorUsername: 'Budi',
      authorAvatarUrl: '',
      caption: 'Biscuit and Nugget both want my laptop during finals week 💻',
      photoUrls: ['https://placekittens.com/400/301'],
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 41,
      comments: 12,
    ),
    CatPost(
      id: '3',
      cats: [Cat(id: 'c3', name: 'Luna', department: 'Teknik Fisika', iconUrl: '', isNeutered: true, createdAt: DateTime.now())],
      catIds: ['c3'],
      authorId: 'user_citra',
      authorUsername: 'Citra',
      authorAvatarUrl: '',
      caption: 'Luna decided the laundry basket is her throne today 👑',
      photoUrls: ['https://placekittens.com/400/302'],
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 18,
      comments: 3,
    ),
    CatPost(
      id: '4',
      cats: [Cat(id: 'c4', name: 'Oreo', department: 'Teknik Elektro', iconUrl: '', isNeutered: false, createdAt: DateTime.now())],
      catIds: ['c4'],
      authorId: 'user_dian',
      authorUsername: 'Dian',
      authorAvatarUrl: '',
      caption: 'Oreo tried to eat my ramen. Not sharing. 🍜',
      photoUrls: ['https://placekittens.com/400/303'],
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      likes: 33,
      comments: 7,
    ),
    CatPost(
      id: '5',
      cats: [Cat(id: 'c5', name: 'Pudding', department: 'Arsitektur', iconUrl: '', isNeutered: true, createdAt: DateTime.now())],
      catIds: ['c5'],
      authorId: 'user_eko',
      authorUsername: 'Eko',
      authorAvatarUrl: '',
      caption: "Pudding's Monday mood. Same, buddy. 😴",
      photoUrls: ['https://placekittens.com/400/304'],
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      likes: 57,
      comments: 14,
    ),
  ];

  void _openCompose() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ComposeScreen(
          userCats: _userCats,
          onPost: (post) => setState(() => _posts.insert(0, post)),
        ),
      ),
    );
  }

  void _openProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileManagementScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
            ),
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: _openProfilePage,
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
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              // sign out and let StreamBuilder in main.dart handle navigation
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
        child: ListView.builder(
          itemCount: _posts.length + 2,
          itemBuilder: (_, index) {
            if (index == 0) return ComposeBox(onTap: _openCompose);
            if (index == 1) {
              return Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              );
            }
            return PostCard(post: _posts[index - 2]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        tooltip: 'New post',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
