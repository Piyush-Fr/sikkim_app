import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
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

  final Set<Marker> _markers = <Marker>{
    const Marker(
      markerId: MarkerId('gangtok'),
      position: LatLng(27.3314, 88.6138),
      infoWindow: InfoWindow(title: 'Gangtok', snippet: 'Capital of Sikkim'),
    ),
    const Marker(
      markerId: MarkerId('tsomgo'),
      position: LatLng(27.3744, 88.7639),
      infoWindow: InfoWindow(
        title: 'Tsomgo Lake',
        snippet: 'High altitude lake',
      ),
    ),
    const Marker(
      markerId: MarkerId('pelling'),
      position: LatLng(27.3150, 88.2410),
      infoWindow: InfoWindow(
        title: 'Pelling',
        snippet: 'Views of Kanchenjunga',
      ),
    ),
    const Marker(
      markerId: MarkerId('yuksom'),
      position: LatLng(27.3741, 88.2586),
      infoWindow: InfoWindow(
        title: 'Yuksom',
        snippet: 'Historic first capital',
      ),
    ),
    const Marker(
      markerId: MarkerId('rumtek'),
      position: LatLng(27.3216, 88.6129),
      infoWindow: InfoWindow(title: 'Rumtek Monastery'),
    ),
  };

  @override
  void initState() {
    super.initState();
    _loadStyle();
    _requestLocationPermission();
    // Failsafe: stop loading spinner if map creation stalls
    _watchdog = Timer(const Duration(seconds: 10), () {
      if (mounted && _loading) setState(() => _loading = false);
    });
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

  @override
  Widget build(BuildContext context) {
    final bool useLiteMode = defaultTargetPlatform == TargetPlatform.android;
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
