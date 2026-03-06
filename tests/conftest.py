import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock

@pytest.fixture
def mock_db():
    db = MagicMock()
    return db