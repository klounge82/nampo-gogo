import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/place.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../l10n/app_localizations.dart';
import '../repositories/place_repository.dart';
import '../services/location_service.dart';
import '../screens/spatial_geometry_editor_screen.dart';

enum PlaceType { point, site, district, linear, largeArea }

enum GeometryType { pointRadius, polygonArea, lineBuffer, multiArea }

enum LocationState { loading, ready, permissionDenied, serviceOff, unavailable }

class PlaceSpatialConfig {
  final PlaceType placeType;
  final GeometryType geometryType;
  final List<LatLng> corridorCoordinates;
  final List<List<LatLng>> lines;
  final double bufferWidthM;
  final bool isApprovedByPm;
  final String noticeMessage;

  const PlaceSpatialConfig({
    required this.placeType,
    required this.geometryType,
    this.corridorCoordinates = const [],
    this.lines = const [],
    this.bufferWidthM = 75.0,
    this.isApprovedByPm = true,
    this.noticeMessage = '',
  });

  PlaceSpatialConfig copyWith({
    List<LatLng>? corridorCoordinates,
    List<List<LatLng>>? lines,
    double? bufferWidthM,
    bool? isApprovedByPm,
  }) {
    return PlaceSpatialConfig(
      placeType: placeType,
      geometryType: geometryType,
      corridorCoordinates: corridorCoordinates ?? this.corridorCoordinates,
      lines: lines ?? this.lines,
      bufferWidthM: bufferWidthM ?? this.bufferWidthM,
      isApprovedByPm: isApprovedByPm ?? this.isApprovedByPm,
      noticeMessage: noticeMessage,
    );
  }
}

class MissionEligibleAreaMap extends StatefulWidget {
  final String storeId;
  final String authType;

  const MissionEligibleAreaMap({
    super.key,
    required this.storeId,
    required this.authType,
  });

  @override
  State<MissionEligibleAreaMap> createState() => _MissionEligibleAreaMapState();
}

class _MissionEligibleAreaMapState extends State<MissionEligibleAreaMap> {
  final PlaceRepository _placeRepository = PlaceRepository();
  GoogleMapController? _mapController;

  Place? _place;
  Position? _userPosition;
  bool _isLoadingPlace = true;
  LocationState _locationState = LocationState.loading;

  late PlaceSpatialConfig _spatialConfig;
  int _distToBoundaryM = 0;
  int _distToCenterM = 0;
  bool _isInside = false;

  @override
  void initState() {
    super.initState();
    _loadPlaceAndLocation();
  }

  Future<void> _loadPlaceAndLocation() async {
    setState(() {
      _isLoadingPlace = true;
      _locationState = LocationState.loading;
    });

    try {
      if (widget.storeId.isNotEmpty) {
        final place = await _placeRepository.getPlaceDetail(widget.storeId);
        _place = place;
        _spatialConfig = _resolveSpatialConfig(place);
      }
    } catch (_) {
      _spatialConfig = const PlaceSpatialConfig(
        placeType: PlaceType.point,
        geometryType: GeometryType.pointRadius,
      );
    } finally {
      if (mounted) setState(() => _isLoadingPlace = false);
    }

    await _fetchUserLocation(autoRecenter: true);
  }

  Future<void> _fetchUserLocation({bool autoRecenter = false}) async {
    setState(() => _locationState = LocationState.loading);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _locationState = LocationState.serviceOff);
        return;
      }

      PermissionStatus perm = await Permission.locationWhenInUse.status;
      if (perm.isDenied) {
        perm = await Permission.locationWhenInUse.request();
      }
      if (perm.isDenied || perm.isPermanentlyDenied) {
        if (mounted)
          setState(() => _locationState = LocationState.permissionDenied);
        return;
      }

      final pos = await LocationService().getCurrentLocation();
      if (!pos.isMocked) {
        _userPosition = pos;
        _calculateStatus();
        if (mounted) {
          setState(() => _locationState = LocationState.ready);
          if (autoRecenter) {
            _animateBounds();
          }
        }
      } else {
        if (mounted) setState(() => _locationState = LocationState.unavailable);
      }
    } catch (_) {
      if (mounted) setState(() => _locationState = LocationState.unavailable);
    }
  }

  PlaceSpatialConfig _resolveSpatialConfig(Place place) {
    // 1. Check if place contains official LINE_BUFFER geometryData
    if (place.geometryData != null && place.geometryType == 'LINE_BUFFER') {
      try {
        final parsed = jsonDecode(place.geometryData!);
        final List<List<LatLng>> lineList = [];
        if (parsed['lines'] != null) {
          for (var l in parsed['lines']) {
            final List<LatLng> pts = [];
            for (var p in l) {
              pts.add(
                LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
              );
            }
            lineList.add(pts);
          }
        }
        final bufferM = (parsed['buffer_m'] as num?)?.toDouble() ?? 75.0;
        return PlaceSpatialConfig(
          placeType: PlaceType.linear,
          geometryType: GeometryType.lineBuffer,
          lines: lineList,
          corridorCoordinates: lineList.isNotEmpty ? lineList.first : const [],
          bufferWidthM: bufferM,
        );
      } catch (_) {}
    }

    // 2. Check if place contains official POLYGON_AREA geometryData
    if (place.geometryData != null &&
        (place.geometryType == 'POLYGON_AREA' ||
            place.geometryType == 'POLYGON')) {
      return const PlaceSpatialConfig(
        placeType: PlaceType.district,
        geometryType: GeometryType.polygonArea,
      );
    }

    // 3. Check if place contains official MULTIPOLYGON / MULTI_AREA geometryData
    if (place.geometryData != null &&
        (place.geometryType == 'MULTIPOLYGON' ||
            place.geometryType == 'MULTI_AREA')) {
      return const PlaceSpatialConfig(
        placeType: PlaceType.largeArea,
        geometryType: GeometryType.multiArea,
      );
    }

    // 4. Default POINT_RADIUS fallback using place latitude/longitude and reviewLocationRadiusM
    return const PlaceSpatialConfig(
      placeType: PlaceType.point,
      geometryType: GeometryType.pointRadius,
    );
  }

  void _calculateStatus() {
    if (_place == null ||
        _place!.latitude == null ||
        _place!.longitude == null ||
        _userPosition == null) {
      return;
    }

    final uLatLng = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final pLat = _place!.latitude!;
    final pLng = _place!.longitude!;

    _distToCenterM = Geolocator.distanceBetween(
      uLatLng.latitude,
      uLatLng.longitude,
      pLat,
      pLng,
    ).round();

    if (_spatialConfig.geometryType == GeometryType.lineBuffer &&
        _spatialConfig.corridorCoordinates.isNotEmpty) {
      final minDistM = _minDistanceToCorridor(
        uLatLng,
        _spatialConfig.corridorCoordinates,
      );
      final buf = _spatialConfig.bufferWidthM;
      _distToBoundaryM = max(0, (minDistM - buf).round());
      _isInside = minDistM <= buf;
    } else if (_spatialConfig.geometryType == GeometryType.pointRadius) {
      final radius = _place!.reviewLocationRadiusM > 0
          ? _place!.reviewLocationRadiusM
          : 100;
      _distToBoundaryM = max(0, _distToCenterM - radius);
      _isInside = _distToCenterM <= radius;
    } else {
      _distToBoundaryM = 0;
      _isInside = false;
    }
  }

  double _distanceToLineSegment(LatLng p, LatLng p1, LatLng p2) {
    final lat1 = p1.latitude;
    final lng1 = p1.longitude;
    final lat2 = p2.latitude;
    final lng2 = p2.longitude;
    final latP = p.latitude;
    final lngP = p.longitude;

    final dx = (lng2 - lng1) * 111320 * cos(lat1 * pi / 180);
    final dy = (lat2 - lat1) * 111320;
    final px = (lngP - lng1) * 111320 * cos(lat1 * pi / 180);
    final py = (latP - lat1) * 111320;

    final segLenSq = dx * dx + dy * dy;
    if (segLenSq == 0) {
      return Geolocator.distanceBetween(latP, lngP, lat1, lng1);
    }

    final t = max(0.0, min(1.0, (px * dx + py * dy) / segLenSq));
    final projLat = lat1 + t * (lat2 - lat1);
    final projLng = lng1 + t * (lng2 - lng1);

    return Geolocator.distanceBetween(latP, lngP, projLat, projLng);
  }

  double _minDistanceToCorridor(LatLng p, List<LatLng> corridor) {
    if (corridor.isEmpty) return double.infinity;
    if (corridor.length == 1) {
      return Geolocator.distanceBetween(
        p.latitude,
        p.longitude,
        corridor[0].latitude,
        corridor[0].longitude,
      );
    }

    double minDist = double.infinity;
    for (int i = 0; i < corridor.length - 1; i++) {
      final d = _distanceToLineSegment(p, corridor[i], corridor[i + 1]);
      if (d < minDist) {
        minDist = d;
      }
    }
    return minDist;
  }

  void _animateBounds() {
    if (_mapController == null ||
        _place == null ||
        _place!.latitude == null ||
        _place!.longitude == null) {
      return;
    }

    final pLat = _place!.latitude!;
    final pLng = _place!.longitude!;
    final radiusM = _place!.reviewLocationRadiusM > 0
        ? _place!.reviewLocationRadiusM
        : 100;

    final points = <LatLng>[LatLng(pLat, pLng)];

    if (_spatialConfig.geometryType == GeometryType.pointRadius) {
      final latOffset = radiusM / 111320.0;
      final lngOffset = radiusM / (111320.0 * cos(pLat * pi / 180));
      points.add(LatLng(pLat + latOffset, pLng + lngOffset));
      points.add(LatLng(pLat - latOffset, pLng - lngOffset));
    }

    if (_spatialConfig.corridorCoordinates.isNotEmpty) {
      points.addAll(_spatialConfig.corridorCoordinates);
    }

    if (_userPosition != null) {
      points.add(LatLng(_userPosition!.latitude, _userPosition!.longitude));
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final pt in points) {
      minLat = min(minLat, pt.latitude);
      maxLat = max(maxLat, pt.latitude);
      minLng = min(minLng, pt.longitude);
      maxLng = max(maxLng, pt.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.0015, minLng - 0.0015),
      northeast: LatLng(maxLat + 0.0015, maxLng + 0.0015),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _openSpatialEditor() {
    if (_place == null) return;
    final storeLat = _place!.latitude ?? 35.1635;
    final storeLng = _place!.longitude ?? 129.1245;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpatialGeometryEditorScreen(
          placeId: _place!.id,
          placeName: _place!.name,
          placeType: _spatialConfig.placeType,
          geometryType: _spatialConfig.geometryType,
          referencePosition: LatLng(storeLat, storeLng),
          initialPoints: _spatialConfig.corridorCoordinates,
          initialBufferM: _spatialConfig.bufferWidthM,
          initialRadiusM: _place!.reviewLocationRadiusM > 0
              ? _place!.reviewLocationRadiusM.toDouble()
              : 100.0,
          initialApprovalStatus: _spatialConfig.isApprovedByPm
              ? SpatialApprovalStatus.approved
              : SpatialApprovalStatus.candidate,
          onCandidateSaved:
              (
                newPoints,
                newLines,
                newBufferM,
                newRadiusM,
                newStatus,
                pType,
                gType,
                refPos,
              ) {
                setState(() {
                  _spatialConfig = _spatialConfig.copyWith(
                    corridorCoordinates: newPoints,
                    lines: newLines,
                    bufferWidthM: newBufferM,
                    isApprovedByPm:
                        (newStatus == SpatialApprovalStatus.approved),
                  );
                  _calculateStatus();
                });
                _animateBounds();
              },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final modeProvider = Provider.of<AppModeProvider>(context);
    final user = authProvider.currentUser;
    final isAdminUser =
        (user != null && user.isAdmin && modeProvider.isAdminMode);

    if (_isLoadingPlace) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_place == null ||
        _place!.latitude == null ||
        _place!.longitude == null) {
      return const SizedBox.shrink();
    }

    final storeLat = _place!.latitude!;
    final storeLng = _place!.longitude!;
    final radiusM = _place!.reviewLocationRadiusM > 0
        ? _place!.reviewLocationRadiusM
        : 100;

    final markers = <Marker>{};
    final circles = <Circle>{};
    final polylines = <Polyline>{};

    // 1. Current User Location Marker (Distinct Azure Hue)
    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location_pin'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: '내 위치'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          zIndexInt: 10,
        ),
      );
    }

    // 2. POINT_RADIUS Rendering
    if (_spatialConfig.geometryType == GeometryType.pointRadius) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_pin'),
          position: LatLng(storeLat, storeLng),
          infoWindow: InfoWindow(title: _place!.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
      circles.add(
        Circle(
          circleId: const CircleId('eligible_area_circle'),
          center: LatLng(storeLat, storeLng),
          radius: radiusM.toDouble(),
          strokeColor: AppColors.primary,
          strokeWidth: 2,
          fillColor: AppColors.primary.withAlpha(40),
        ),
      );
    }

    // 3. LINEAR Line Buffer Rendering (Suyeong River Promenade)
    if (_spatialConfig.geometryType == GeometryType.lineBuffer &&
        _spatialConfig.corridorCoordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('linear_corridor_line'),
          points: _spatialConfig.corridorCoordinates,
          color: AppColors.primary,
          width: 6,
        ),
      );

      if (isAdminUser) {
        markers.add(
          Marker(
            markerId: const MarkerId('reference_neutral_pin'),
            position: LatLng(storeLat, storeLng),
            infoWindow: InfoWindow(title: '${_place!.name} 대표 위치 (참고용)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _spatialConfig.placeType == PlaceType.linear
                      ? l10n.spatialMapTitleSuyeong
                      : l10n.spatialMapTitleDefault,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _spatialConfig.geometryType == GeometryType.pointRadius
                        ? l10n.missionEligibleRadius100m(radiusM)
                        : l10n.spatialMapApprovedTrail,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Map Viewport Container (Free-Pan + GestureRecognizers Enabled)
          SizedBox(
            height: 230,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(storeLat, storeLng),
                    zoom: 16.0,
                  ),
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  markers: markers,
                  circles: circles,
                  polylines: polylines,
                  myLocationEnabled: _locationState == LocationState.ready,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _animateBounds();
                  },
                ),

                // Small non-blocking top-right chip
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(190),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _spatialConfig.isApprovedByPm
                              ? Icons.verified
                              : Icons.info_outline,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.spatialMapApprovedTrail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Informational Notice Box
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            color: AppColors.background,
            child: Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _spatialConfig.placeType == PlaceType.linear
                        ? l10n.spatialMapTitleSuyeong
                        : (_spatialConfig.placeType == PlaceType.district ||
                                  _spatialConfig.placeType ==
                                      PlaceType.largeArea
                              ? l10n.missionDistrictTypeNotice
                              : l10n.spatialMapTitleDefault),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Location-First Status & Safety Gate Section
          _buildStatusSection(),

          // 5. Control Bar (ADMIN ONLY Spatial Editor Button)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _fetchUserLocation(autoRecenter: true),
                    icon: _locationState == LocationState.loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 16),
                    label: Text(
                      l10n.myLocationCheckButton,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                // TASK 1: Edit button ONLY rendered for ADMIN users! (Hidden for CUSTOMER & BUSINESS)
                if (isAdminUser) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openSpatialEditor,
                    icon: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text(
                      '공간 인증범위 편집 (ADMIN)',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final l10n = AppLocalizations.of(context)!;
    switch (_locationState) {
      case LocationState.loading:
        return Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.blue.withAlpha(15),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.mapLoading,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case LocationState.permissionDenied:
        return Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.amber.withAlpha(20),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.mapPermissionRequired,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );

      case LocationState.serviceOff:
        return Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.amber.withAlpha(20),
          child: Row(
            children: [
              const Icon(Icons.location_off, color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.mapPermissionRequired,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );

      case LocationState.unavailable:
        return Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.grey.withAlpha(20),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.mapLoadFail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );

      case LocationState.ready:
        if (_userPosition == null) return const SizedBox.shrink();

        // Safety Gate: Unapproved Geometry Candidate Status
        if (!_spatialConfig.isApprovedByPm) {
          return Container(
            padding: const EdgeInsets.all(14.0),
            color: Colors.amber.withAlpha(20),
            child: Row(
              children: [
                const Icon(
                  Icons.rule_folder_outlined,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.spatialMapCandidateTrail,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.spatialMapCandidateNotice,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14.0),
          color: _isInside
              ? Colors.green.withAlpha(15)
              : Colors.orange.withAlpha(15),
          child: Row(
            children: [
              Icon(
                _isInside ? Icons.check_circle_outline : Icons.error_outline,
                color: _isInside ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInside
                          ? l10n.spatialMapInsideNotice
                          : l10n.spatialMapOutsideNotice,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isInside
                            ? Colors.green[800]
                            : Colors.orange[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isInside
                          ? l10n.spatialMapCanVerifyImmediately
                          : '${l10n.spatialMapOutsideNotice} (${_distToBoundaryM}m)',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isInside
                            ? Colors.green[700]
                            : Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}
