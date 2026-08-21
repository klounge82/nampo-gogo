import unittest
import sys
import os
import json

repo_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.append(repo_dir)

from app.main import (
    haversine_distance_m,
    distance_point_to_segment_m,
    distance_point_to_polyline_m,
    point_in_polygon,
    evaluate_spatial_position
)

class MockStore:
    def __init__(self, latitude=35.0995, longitude=129.0315, review_location_radius_m=50, geometry_type="POINT_RADIUS", geometry_data=None):
        self.latitude = latitude
        self.longitude = longitude
        self.review_location_radius_m = review_location_radius_m
        self.geometry_type = geometry_type
        self.geometry_data = geometry_data

class TestMC05SpatialEngine(unittest.TestCase):

    def test_point_radius_inside_and_outside(self):
        # K-Lounge center: (35.0995, 129.0315), radius: 50m
        store = MockStore(latitude=35.0995, longitude=129.0315, review_location_radius_m=50)

        # 1. User right at center (35.0995, 129.0315)
        res1 = evaluate_spatial_position(35.0995, 129.0315, store)
        self.assertTrue(res1["inside"])
        self.assertEqual(res1["distance_m"], 0)

        # 2. User ~20m away
        res2 = evaluate_spatial_position(35.0996, 129.0316, store)
        self.assertTrue(res2["inside"])

        # 3. User ~500m away
        res3 = evaluate_spatial_position(35.1050, 129.0350, store)
        self.assertFalse(res3["inside"])
        self.assertGreater(res3["outside_by_m"], 0)

    def test_line_buffer_corridor(self):
        # Suyeong River line buffer polyline
        pts = [
            {"lat": 35.1650, "lng": 129.1235},
            {"lat": 35.1680, "lng": 129.1250},
            {"lat": 35.1710, "lng": 129.1270}
        ]
        geom_json = json.dumps({"points": pts, "buffer_m": 50})
        store = MockStore(geometry_type="LINE_BUFFER", geometry_data=geom_json)

        # 1. User near middle segment (35.1680, 129.1250) - 0m away
        res1 = evaluate_spatial_position(35.1680, 129.1250, store)
        self.assertTrue(res1["inside"])
        self.assertEqual(res1["distance_m"], 0)

        # 2. User ~20m away from middle segment
        res2 = evaluate_spatial_position(35.1681, 129.1251, store)
        self.assertTrue(res2["inside"])

        # 3. User ~300m away from riverbank polyline
        res3 = evaluate_spatial_position(35.1750, 129.1350, store)
        self.assertFalse(res3["inside"])

    def test_multi_line_disconnected_buffer(self):
        # Bank A: (35.1650, 129.1235) -> (35.1680, 129.1250)
        # Bank B: (35.1655, 129.1225) -> (35.1685, 129.1240) (disconnected, parallel across river)
        lines = [
            [{"lat": 35.1650, "lng": 129.1235}, {"lat": 35.1680, "lng": 129.1250}],
            [{"lat": 35.1655, "lng": 129.1225}, {"lat": 35.1685, "lng": 129.1240}]
        ]
        geom_json = json.dumps({"lines": lines, "buffer_m": 50})
        store = MockStore(geometry_type="LINE_BUFFER", geometry_data=geom_json)

        # 1. User near Bank A
        res_a = evaluate_spatial_position(35.1650, 129.1235, store)
        self.assertTrue(res_a["inside"])

        # 2. User near Bank B
        res_b = evaluate_spatial_position(35.1655, 129.1225, store)
        self.assertTrue(res_b["inside"])

        # 3. User far from both banks (e.g. 500m away)
        res_far = evaluate_spatial_position(35.1800, 129.1400, store)
        self.assertFalse(res_far["inside"])

    def test_polygon_area_containment(self):
        # Square polygon
        pts = [
            {"lat": 35.1000, "lng": 129.0300},
            {"lat": 35.1020, "lng": 129.0300},
            {"lat": 35.1020, "lng": 129.0320},
            {"lat": 35.1000, "lng": 129.0320}
        ]
        geom_json = json.dumps({"points": pts})
        store = MockStore(geometry_type="POLYGON_AREA", geometry_data=geom_json)

        # 1. User inside square (35.1010, 129.0310)
        res1 = evaluate_spatial_position(35.1010, 129.0310, store)
        self.assertTrue(res1["inside"])
        self.assertEqual(res1["distance_m"], 0)

        # 2. User outside square (35.1050, 129.0350)
        res2 = evaluate_spatial_position(35.1050, 129.0350, store)
        self.assertFalse(res2["inside"])

    def test_legacy_fallback(self):
        # Store with null geometry_type
        store = MockStore(geometry_type=None, geometry_data=None)
        res = evaluate_spatial_position(35.0995, 129.0315, store)
        self.assertEqual(res["geometry_type"], "POINT_RADIUS")
        self.assertTrue(res["inside"])

if __name__ == "__main__":
    unittest.main()
