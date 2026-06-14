import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/cat_post.dart';
import '../services/post_service.dart';

class MapViewOverlay extends StatefulWidget {
  const MapViewOverlay({super.key});

  @override
  State<MapViewOverlay> createState() => _MapViewOverlayState();
}

class _MapViewOverlayState extends State<MapViewOverlay> {
  bool _isExpanded = false;
  Set<Marker> _markers = {};
  StreamSubscription<List<CatPost>>? _sub;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(-7.279604, 112.797274),
    zoom: 15.5,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub?.cancel();
    final postService = Provider.of<PostService>(context, listen: false);
    _sub = postService.streamFeed().listen(_buildMarkers);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _buildMarkers(List<CatPost> posts) {
    final markers = <Marker>{};
    for (final post in posts) {
      if (post.location == null) continue;
      final pos = LatLng(post.location!.latitude, post.location!.longitude);
      markers.add(Marker(
        markerId: MarkerId(post.id),
        position: pos,
        infoWindow: InfoWindow(
          title: post.authorUsername,
          snippet: post.caption.length > 60
              ? '${post.caption.substring(0, 60)}…'
              : post.caption,
        ),
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Cat Sightings Map',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (_markers.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_markers.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _isExpanded ? 'Hide' : 'Show',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
                const SizedBox(width: 2),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: cs.primary,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isExpanded
              ? SizedBox(
                  height: 220,
                  child: GoogleMap(
                    initialCameraPosition: _initialCamera,
                    markers: _markers,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Divider(height: 1, thickness: 1, color: cs.outlineVariant),
      ],
    );
  }
}
