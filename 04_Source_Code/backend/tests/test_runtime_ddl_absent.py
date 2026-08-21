import unittest
import inspect
from app import main

class TestRuntimeDDLAbsent(unittest.TestCase):
    def test_migrate_spatial_columns_function_absent(self):
        self.assertFalse(hasattr(main, 'migrate_spatial_columns_if_missing'), 
                         "migrate_spatial_columns_if_missing() must be ABSENT from main.py in production runtime!")

    def test_on_startup_has_no_ddl(self):
        source = inspect.getsource(main.on_startup)
        self.assertNotIn("ALTER TABLE", source, "on_startup() must NOT contain auto-DDL statements!")
        self.assertNotIn("migrate_spatial_columns_if_missing", source, "on_startup() must NOT execute migrate_spatial_columns_if_missing!")

if __name__ == '__main__':
    unittest.main()
