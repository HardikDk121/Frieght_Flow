import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/models/freight_route.dart';
import '../../../../core/models/trip.dart';
import '../../../../core/theme/app_colors.dart';

class LiveMapWidget extends StatefulWidget {
  final Trip trip;
  final FreightRoute route;
  const LiveMapWidget({super.key, required this.trip, required this.route});
  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _controller;

  static const Map<String, LatLng> _cityCoords = {
    'Rajkot':    LatLng(22.3039, 70.8022),
    'Mumbai':    LatLng(19.0760, 72.8777),
    'Delhi':     LatLng(28.6139, 77.2090),
    'Bangalore': LatLng(12.9716, 77.5946),
    'Pune':      LatLng(18.5204, 73.8567),
    'Ahmedabad': LatLng(23.0225, 72.5714),
    'Chennai':   LatLng(13.0827, 80.2707),
  };

  LatLng? get _originCoord => _cityCoords[widget.route.origin];
  LatLng? get _destCoord   => _cityCoords[widget.route.destination];
  LatLng? get _truckPos    => widget.trip.currentLocation != null
      ? LatLng(widget.trip.currentLocation!.latitude, widget.trip.currentLocation!.longitude)
      : null;

  Set<Marker> _markers() {
    final m = <Marker>{};
    if (_originCoord != null) m.add(Marker(markerId: const MarkerId('origin'), position: _originCoord!, infoWindow: InfoWindow(title: widget.route.origin, snippet: 'Origin'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)));
    if (_destCoord   != null) m.add(Marker(markerId: const MarkerId('dest'),   position: _destCoord!,   infoWindow: InfoWindow(title: widget.route.destination, snippet: 'Destination'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)));
    if (_truckPos    != null) m.add(Marker(markerId: const MarkerId('truck'),  position: _truckPos!,   infoWindow: const InfoWindow(title: 'Truck'), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)));
    return m;
  }

  Set<Polyline> _polylines() {
    if (_originCoord == null || _destCoord == null) return {};
    return { Polyline(polylineId: const PolylineId('r'), points: [_originCoord!, _destCoord!], color: AppColors.primary, width: 4, patterns: [PatternItem.dash(20), PatternItem.gap(10)]) };
  }

  CameraPosition _camera() {
    if (_originCoord != null && _destCoord != null) {
      return CameraPosition(target: LatLng((_originCoord!.latitude + _destCoord!.latitude) / 2, (_originCoord!.longitude + _destCoord!.longitude) / 2), zoom: 5.5);
    }
    return const CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 4.5);
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 240,
        child: GoogleMap(
          initialCameraPosition: _camera(),
          markers: _markers(),
          polylines: _polylines(),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          onMapCreated: (c) { _controller = c; },
        ),
      ),
    );
  }
}