import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationPickerScreen extends StatefulWidget {
  final GeoPoint? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _itsDefault = LatLng(-7.279604, 112.797274);

  late LatLng _pickedPosition;
  LatLng _displayPosition = _itsDefault;

  @override
  void initState() {
    super.initState();
    _pickedPosition = widget.initialLocation != null
        ? LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          )
        : _itsDefault;
    _displayPosition = _pickedPosition;
  }

  String _formatLatLng(LatLng pos) {
    final lat = pos.latitude.abs().toStringAsFixed(5);
    final lng = pos.longitude.abs().toStringAsFixed(5);
    final latDir = pos.latitude >= 0 ? 'N' : 'S';
    final lngDir = pos.longitude >= 0 ? 'E' : 'W';
    return '$lat° $latDir,  $lng° $lngDir';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        leadingWidth: 80,
        title: const Text(
          'Set Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                GeoPoint(
                  _pickedPosition.latitude,
                  _pickedPosition.longitude,
                ),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: const StadiumBorder(),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedPosition,
              zoom: 16,
            ),
            onCameraMove: (position) {
              _pickedPosition = position.target;
            },
            onCameraIdle: () {
              setState(() => _displayPosition = _pickedPosition);
            },
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),
          // Center crosshair — pin tail sits on the exact map coordinate
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_pin, color: Colors.red, size: 48),
            ),
          ),
          // Coordinate card at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.my_location, color: cs.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Drag map to move pin',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatLatLng(_displayPosition),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
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
