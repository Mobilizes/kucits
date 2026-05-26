import 'package:flutter/material.dart';

class ComposeBox extends StatelessWidget {
  final VoidCallback onTap;

  const ComposeBox({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cs.primaryContainer,
              child: Icon(Icons.person, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "What's your cat up to?",
                style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Post',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
