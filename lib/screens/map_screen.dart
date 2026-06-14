import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/cat_post.dart';
import '../services/post_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<Marker> _markers = {};
  StreamSubscription<List<CatPost>>? _sub;
  GoogleMapController? _mapController;

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
    _mapController?.dispose();
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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '🐱 ${post.authorUsername}',
          snippet: post.caption.length > 80
              ? '${post.caption.substring(0, 80)}…'
              : post.caption,
        ),
      ));
    }
    if (mounted) setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cat Sightings Map',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            if (_markers.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_markers.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          // Pin indicator overlay
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _markers.isEmpty
                          ? 'No sightings yet'
                          : '${_markers.length} cat ${_markers.length == 1 ? 'sighting' : 'sightings'} nearby',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
