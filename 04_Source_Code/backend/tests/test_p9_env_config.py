import unittest
import os
import ast
import importlib
from app import database

class TestDatabaseEnvConfig(unittest.TestCase):

    def setUp(self):
        # Save original environment state
        self.original_env = os.environ.copy()

    def tearDown(self):
        # Restore environment completely
        os.environ.clear()
        os.environ.update(self.original_env)

        # Restore safe SQLite configuration in module
        os.environ["DATABASE_URL"] = "sqlite:///:memory:"
        os.environ["APP_ENV"] = "test"
        try:
            importlib.reload(database)
        except Exception:
            pass

    def test_e1_explicit_sqlite_database_url(self):
        """E1: Explicit SQLite DATABASE_URL succeeds without POSTGRES_PASSWORD"""
        os.environ["DATABASE_URL"] = "sqlite:///:memory:"
        os.environ.pop("POSTGRES_PASSWORD", None)
        os.environ["APP_ENV"] = "test"

        mod = importlib.reload(database)
        self.assertEqual(mod.engine.url.drivername, "sqlite")

    def test_e2_placeholder_with_explicit_password(self):
        """E2: Placeholder substitution occurs when explicit POSTGRES_PASSWORD is provided"""
        os.environ["DATABASE_URL"] = "postgresql://user:CHANGE_ME@127.0.0.1:5432/testdb"
        os.environ["POSTGRES_PASSWORD"] = "dummy_test_pass"
        os.environ["APP_ENV"] = "test"

        mod = importlib.reload(database)
        self.assertNotIn("CHANGE_ME", mod.db_url)
        self.assertEqual(mod.engine.url.password, "dummy_test_pass")

    def test_e3_missing_password_production_fails_closed(self):
        """E3: Missing password with CHANGE_ME in production raises RuntimeError"""
        os.environ["DATABASE_URL"] = "postgresql://user:CHANGE_ME@127.0.0.1:5432/testdb"
        os.environ.pop("POSTGRES_PASSWORD", None)
        os.environ["APP_ENV"] = "production"

        with self.assertRaises(RuntimeError) as ctx:
            importlib.reload(database)
        self.assertIn("DATABASE_CONFIG_ERROR", str(ctx.exception))

    def test_e4_missing_password_development_fails_closed(self):
        """E4: Missing password with CHANGE_ME in development raises ValueError"""
        os.environ["DATABASE_URL"] = "postgresql://user:CHANGE_ME@127.0.0.1:5432/testdb"
        os.environ.pop("POSTGRES_PASSWORD", None)
        os.environ["APP_ENV"] = "development"

        with self.assertRaises(ValueError) as ctx:
            importlib.reload(database)
        self.assertIn("DATABASE_CONFIG_ERROR", str(ctx.exception))

    def test_e5_default_sqlite_without_password(self):
        """E5: Default SQLite URL path used when DATABASE_URL is unset"""
        os.environ.pop("DATABASE_URL", None)
        os.environ.pop("POSTGRES_PASSWORD", None)
        os.environ["APP_ENV"] = "test"

        mod = importlib.reload(database)
        self.assertEqual(mod.engine.url.drivername, "sqlite")
        self.assertIn("nampo_gogo_test.db", mod.db_url)

    def test_e6_postgres_password_getenv_has_no_default(self):
        """E6: AST static analysis confirms os.getenv('POSTGRES_PASSWORD') has no default fallback literal"""
        db_file = os.path.join(os.path.dirname(database.__file__), "database.py")
        with open(db_file, "r", encoding="utf-8") as f:
            tree = ast.parse(f.read())

        found_getenv = False
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                func = node.func
                if isinstance(func, ast.Attribute) and func.attr == "getenv":
                    if node.args and isinstance(node.args[0], ast.Constant) and node.args[0].value == "POSTGRES_PASSWORD":
                        found_getenv = True
                        self.assertEqual(len(node.args), 1, "Expected os.getenv('POSTGRES_PASSWORD') to have exactly 1 argument")
                        self.assertEqual(len(node.keywords), 0, "Expected no keyword arguments for default fallback")

        self.assertTrue(found_getenv, "Expected to find os.getenv('POSTGRES_PASSWORD') call in database.py")

if __name__ == "__main__":
    unittest.main()
