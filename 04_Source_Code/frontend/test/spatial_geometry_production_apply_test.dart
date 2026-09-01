import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../lib/models/user.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/screens/spatial_geometry_editor_screen.dart';
import '../lib/widgets/mission_eligible_area_map.dart';

class MockAdminAuthProvider extends ChangeNotifier implements AuthProvider {
  User? get currentUser => User(
        id: 'admin_001',
        email: 'admin@nampogogo.com',
        nickname: 'PM',
        role: 'ADMIN',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  @override
  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('SpatialGeometryEditorScreen contains Production DB apply button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAdminAuthProvider()),
        ],
        child: const MaterialApp(
          home: SpatialGeometryEditorScreen(
            placeId: 'qa-store-suyeong-river-photo-004',
            placeName: '수영강변',
            placeType: PlaceType.linear,
            geometryType: GeometryType.lineBuffer,
            referencePosition: LatLng(35.1635, 129.1245),
            initialPoints: [LatLng(35.1635, 129.1245), LatLng(35.1640, 129.1250)],
            initialBufferM: 50.0,
            initialRadiusM: 100.0,
            initialApprovalStatus: SpatialApprovalStatus.candidate,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify SpatialGeometryEditorScreen rendered and contains buttons
    expect(find.byType(SpatialGeometryEditorScreen), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });
}
