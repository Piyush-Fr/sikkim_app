import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sikkim_app/screens/chatbot.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class StreetViewExample extends StatefulWidget {
  @override
  _StreetViewExampleState createState() => _StreetViewExampleState();
}

class _StreetViewExampleState extends State<StreetViewExample> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  bool _locationPermissionGranted = false;
  String? _error;
  bool _loading = true;
  Timer? _watchdog;

  static const LatLng _sikkimCenter = LatLng(27.5330, 88.5122); // Near Gangtok

  final Set<Marker> _markers = <Marker>{};

  Marker _buildMarker({
    required String id,
    required LatLng position,
    required String title,
    String? snippet,
  }) {
    void openActions() => _showMarkerActions(title);
    return Marker(
      markerId: MarkerId(id),
      position: position,
      onTap: openActions,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
        onTap: openActions,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadStyle();
    _requestLocationPermission();
    // Failsafe: stop loading spinner if map creation stalls
    _watchdog = Timer(const Duration(seconds: 10), () {
      if (mounted && _loading) setState(() => _loading = false);
    });
    // Build markers with actions
    _markers
      ..clear()
      ..addAll([
        _buildMarker(
          id: 'gangtok',
          position: const LatLng(27.3314, 88.6138),
          title: 'Gangtok',
          snippet: 'Capital of Sikkim',
        ),
        _buildMarker(
          id: 'tsomgo',
          position: const LatLng(27.3744, 88.7639),
          title: 'Tsomgo Lake',
          snippet: 'High altitude lake',
        ),
        _buildMarker(
          id: 'pelling',
          position: const LatLng(27.3150, 88.2410),
          title: 'Pelling',
          snippet: 'Views of Kanchenjunga',
        ),
        _buildMarker(
          id: 'yuksom',
          position: const LatLng(27.3741, 88.2586),
          title: 'Yuksom',
          snippet: 'Historic first capital',
        ),
        _buildMarker(
          id: 'rumtek',
          position: const LatLng(27.3216, 88.6129),
          title: 'Rumtek Monastery',
        ),
      ]);
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  Future<void> _loadStyle() async {
    try {
      final style = await rootBundle.loadString('assets/map/style.json');
      if (mounted) setState(() => _mapStyle = style);
    } catch (_) {
      // style is optional; ignore errors
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (mounted)
        setState(() => _locationPermissionGranted = status.isGranted);
    } catch (e) {
      if (mounted) setState(() => _error = 'Permission error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    try {
      if (_mapStyle != null) {
        await _mapController!.setMapStyle(_mapStyle);
      }
    } catch (_) {
      // Ignore styling errors
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _recenter() async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: _sikkimCenter,
          zoom: 8.8,
          tilt: 0,
          bearing: 0,
        ),
      ),
    );
  }

  // Custom zoom controls removed; touch gestures handle zooming

  void _showMarkerActions(String placeName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  placeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.question_answer,
                    color: Colors.white,
                  ),
                  title: const Text(
                    'Ask Sikky about this',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    final query = 'Tell me about $placeName';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Chatbot(initialQuery: query),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool useLiteMode = false; // enable full interactivity (pan/zoom)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sikkim Map'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _sikkimCenter,
              zoom: 8.8,
            ),
            markers: _markers,
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: false,
            tiltGesturesEnabled: false,
            compassEnabled: false,
            indoorViewEnabled: false,
            mapType: MapType.normal,
            liteModeEnabled: useLiteMode,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _recenter,
        backgroundColor: Colors.white,
        child: const Icon(Icons.center_focus_strong, color: Colors.black),
        tooltip: 'Recenter on Sikkim',
      ),
    );
  }
}
