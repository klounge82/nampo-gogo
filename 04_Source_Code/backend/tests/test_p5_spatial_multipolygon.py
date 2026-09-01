import unittest
import json
from types import SimpleNamespace
from app.main import evaluate_spatial_position

class TestSpatialMultiPolygon(unittest.TestCase):

    def setUp(self):
        # Two distinct non-overlapping polygons
        # Poly 1: around (35.100, 129.030)
        # Poly 2: around (35.200, 129.040)
        self.poly1 = [
            {"lat": 35.090, "lng": 129.020},
            {"lat": 35.110, "lng": 129.020},
            {"lat": 35.110, "lng": 129.040},
            {"lat": 35.090, "lng": 129.040}
        ]
        self.poly2 = [
            {"lat": 35.190, "lng": 129.030},
            {"lat": 35.210, "lng": 129.030},
            {"lat": 35.210, "lng": 129.050},
            {"lat": 35.190, "lng": 129.050}
        ]

    def test_s1_multipolygon_member1_inside(self):
        """S1: Point inside member polygon #1 returns inside=True, distance_m=0, outside_by_m=0"""
        store = SimpleNamespace(
            geometry_type="MULTIPOLYGON",
            geometry_data=json.dumps({"polygons": [self.poly1, self.poly2]}),
            latitude=35.100,
            longitude=129.030,
            review_location_radius_m=50.0
        )
        res = evaluate_spatial_position(35.100, 129.030, store)

        self.assertTrue(res["inside"])
        self.assertEqual(res["distance_m"], 0)
        self.assertEqual(res["outside_by_m"], 0)
        self.assertEqual(res["geometry_type"], "MULTIPOLYGON")

    def test_s2_multipolygon_member2_inside(self):
        """S2: Point inside member polygon #2 returns inside=True (also testing MULTIPOLYGON_AREA alias)"""
        store = SimpleNamespace(
            geometry_type="MULTIPOLYGON_AREA",
            geometry_data=json.dumps({"polygons": [self.poly1, self.poly2]}),
            latitude=35.200,
            longitude=129.040,
            review_location_radius_m=50.0
        )
        res = evaluate_spatial_position(35.200, 129.040, store)

        self.assertTrue(res["inside"])
        self.assertEqual(res["distance_m"], 0)
        self.assertEqual(res["outside_by_m"], 0)
        self.assertEqual(res["geometry_type"], "MULTIPOLYGON")

    def test_s3_multipolygon_outside_all(self):
        """S3: Point outside all member polygons returns inside=False with distance > 0"""
        store = SimpleNamespace(
            geometry_type="MULTIPOLYGON",
            geometry_data=json.dumps({"polygons": [self.poly1, self.poly2]}),
            latitude=35.150,
            longitude=129.035,
            review_location_radius_m=50.0
        )
        res = evaluate_spatial_position(35.150, 129.035, store)

        self.assertFalse(res["inside"])
        self.assertGreater(res["distance_m"], 0)
        self.assertGreater(res["outside_by_m"], 0)
        self.assertEqual(res["geometry_type"], "MULTIPOLYGON")

    def test_s4_multipolygon_malformed_safe_false(self):
        """S4: Malformed/empty member polygons safely return inside=False, distance_m=0, outside_by_m=0 without exception"""
        store = SimpleNamespace(
            geometry_type="MULTIPOLYGON",
            geometry_data=json.dumps({"polygons": [[{"lat": 35.0, "lng": 129.0}], "invalid_entry", []]}),
            latitude=35.100,
            longitude=129.030,
            review_location_radius_m=50.0
        )
        res = evaluate_spatial_position(35.100, 129.030, store)

        self.assertFalse(res["inside"])
        self.assertEqual(res["distance_m"], 0)
        self.assertEqual(res["outside_by_m"], 0)
        self.assertEqual(res["geometry_type"], "MULTIPOLYGON")

    def test_s5_polygon_area_nonregression(self):
        """S5: Existing single POLYGON_AREA behaves correctly"""
        store = SimpleNamespace(
            geometry_type="POLYGON_AREA",
            geometry_data=json.dumps({"points": self.poly1}),
            latitude=35.100,
            longitude=129.030,
            review_location_radius_m=50.0
        )
        res = evaluate_spatial_position(35.100, 129.030, store)

        self.assertTrue(res["inside"])
        self.assertEqual(res["geometry_type"], "POLYGON_AREA")

    def test_s6_point_radius_nonregression(self):
        """S6: Existing POINT_RADIUS behaves correctly"""
        store = SimpleNamespace(
            geometry_type="POINT_RADIUS",
            geometry_data=None,
            latitude=35.1000,
            longitude=129.0300,
            review_location_radius_m=100.0
        )
        # Point ~10m away
        res = evaluate_spatial_position(35.10005, 129.03005, store)

        self.assertTrue(res["inside"])
        self.assertEqual(res["geometry_type"], "POINT_RADIUS")

    def test_s7_line_buffer_nonregression(self):
        """S7: Existing LINE_BUFFER behaves correctly"""
        store = SimpleNamespace(
            geometry_type="LINE_BUFFER",
            geometry_data=json.dumps({
                "points": [{"lat": 35.1000, "lng": 129.0300}, {"lat": 35.1010, "lng": 129.0300}],
                "buffer_m": 50.0
            }),
            latitude=35.1000,
            longitude=129.0300,
            review_location_radius_m=50.0
        )
        res = evaluate_spatial_position(35.1005, 129.0301, store)

        self.assertTrue(res["inside"])
        self.assertEqual(res["geometry_type"], "LINE_BUFFER")

if __name__ == "__main__":
    unittest.main()
