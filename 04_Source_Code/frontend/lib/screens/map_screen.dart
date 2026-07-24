import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../models/place.dart';
import '../repositories/map_repository.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import 'place_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapService _mapService = MapService();
  final MapRepository _mapRepository = MapRepository();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<Place> _places = [];
  Set<Marker> _markers = {};

  // Selected place for bottom info card
  Place? _selectedPlace;
  bool _isLoading = true;

  // Initial Camera position set to Busan Station (Fallback center)
  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(
      LocationService.fallbackLatitude,
      LocationService.fallbackLongitude,
    ),
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    // 1. Fetch current GPS location
    final position = await _locationService.getCurrentLocation();

    // 2. Fetch place markers
    final list = await _mapRepository.getMapPlaces();

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _places = list;
        _isLoading = false;
      });
      _buildMarkers();
      _animateToCurrentLocation();
    }
  }

  void _buildMarkers() {
    final Set<Marker> localMarkers = {};

    for (final place in _places) {
      if (place.latitude == null || place.longitude == null) continue;

      // Assign category hues (MAP-001 category mark specs)
      double markerHue = BitmapDescriptor.hueRed; // Default food
      if (place.category.contains('카페')) {
        markerHue = BitmapDescriptor.hueOrange;
      } else if (place.category.contains('관광') ||
          place.category.contains('볼거리')) {
        markerHue = BitmapDescriptor.hueAzure;
      } else if (place.category.contains('쇼핑')) {
        markerHue = BitmapDescriptor.hueGreen;
      } else if (place.category.contains('체험') ||
          place.category.contains('문화')) {
        markerHue = BitmapDescriptor.hueViolet;
      }

      localMarkers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: LatLng(place.latitude!, place.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          onTap: () {
            setState(() {
              _selectedPlace = place;
            });
          },
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.category} · ★ ${place.rating.toStringAsFixed(1)}',
          ),
        ),
      );
    }

    setState(() {
      _markers = localMarkers;
    });
  }

  Future<void> _animateToCurrentLocation() async {
    if (_mapController == null || _currentPosition == null) return;

    final controller = _mapController!;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  /// Calculates straight-line distance in meters using Geolocator
  int _calculateDistance(Place place) {
    if (_currentPosition == null ||
        place.latitude == null ||
        place.longitude == null) {
      return 0;
    }
    final double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.latitude!,
      place.longitude!,
    );
    return distanceInMeters.round();
  }

  /// Calculates estimated walking duration based on standard speed (80m / min)
  int _calculateWalkingMinutes(int distanceInMeters) {
    if (distanceInMeters <= 0) return 0;
    // Standard speed: 80 meters per minute (approx. 4.8 km/h)
    final double minutes = distanceInMeters / 80.0;
    return minutes.ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Google Map Component
          GoogleMap(
            initialCameraPosition: _initialCamera,
            markers: _markers,
            myLocationEnabled:
                _currentPosition != null && !_currentPosition!.isMocked,
            myLocationButtonEnabled: false, // Custom floating button below
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _animateToCurrentLocation();
              }
            },
            onTap: (_) {
              // Dismiss bottom sheet card when map is tapped
              setState(() {
                _selectedPlace = null;
              });
            },
          ),

          // Loading indicator overlay
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(20),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),

          // Custom Position tracker buttons
          Positioned(
            right: 16.0,
            bottom: _selectedPlace != null ? 275.0 : 16.0,
            child: Column(
              children: [
                // Re-center current location button
                FloatingActionButton(
                  heroTag: 'my_location_btn',
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    final position = await _locationService
                        .getCurrentLocation();
                    setState(() {
                      _currentPosition = position;
                      _isLoading = false;
                    });
                    _animateToCurrentLocation();
                  },
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  elevation: 4.0,
                  mini: true,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Selected Place Card Info Bottom Sheet
          if (_selectedPlace != null)
            Positioned(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              child: _buildPlaceInfoCard(_selectedPlace!),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceInfoCard(Place place) {
    final int distance = _calculateDistance(place);
    final int walkingMin = _calculateWalkingMinutes(distance);
    final String distanceStr = distance >= 1000
        ? '${(distance / 1000.0).toStringAsFixed(1)}km'
        : '${distance}m';

    // Status chip colors
    Color statusColor = Colors.green;
    if (place.status == '휴무') {
      statusColor = Colors.grey;
    } else if (place.status == '곧 마감') {
      statusColor = Colors.orange;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Title, Category, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    place.status,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Row(
              children: [
                Text(
                  place.category,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8.0),
                const Icon(Icons.star, color: Colors.amber, size: 14.0),
                const SizedBox(width: 2.0),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Distance / Walking duration details
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 16.0,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '내 위치에서 $distanceStr',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  '(도보 약 $walkingMin분 소요)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),
            const SizedBox(height: 12.0),

            // Route search external Launcher button layouts (MAP-001 Requirement)
            Row(
              children: [
                // Walk routing launcher
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _mapService.launchGoogleMapRoute(
                        destLat: place.latitude!,
                        destLng: place.longitude!,
                        destName: place.name,
                        mode: 'w',
                      );
                    },
                    icon: const Icon(Icons.directions_walk, size: 14.0),
                    label: const Text(
                      '도보 길찾기',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Drive routing launcher
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _mapService.launchGoogleMapRoute(
                        destLat: place.latitude!,
                        destLng: place.longitude!,
                        destName: place.name,
                        mode: 'd',
                      );
                    },
                    icon: const Icon(Icons.directions_car, size: 14.0),
                    label: const Text(
                      '차량 길찾기',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                // Naver Map launcher (Korean localized fallback redirect option)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _mapService.launchNaverMapRoute(
                        destLat: place.latitude!,
                        destLng: place.longitude!,
                        destName: place.name,
                      );
                    },
                    icon: const Icon(
                      Icons.map,
                      size: 14.0,
                      color: Colors.white,
                    ),
                    label: const Text(
                      '네이버지도로 길찾기',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF03C75A,
                      ), // Naver Green Brand
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                // Navigate to DetailsScreen
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(placeId: place.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    height: 38.0,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Center(
                      child: Text(
                        '상세보기',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
