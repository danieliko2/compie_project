import pytest
from unittest.mock import MagicMock, patch

# Mock the dynamodb table creation at import time so tests never need a real table name
@pytest.fixture(autouse=True)
def mock_dynamodb_table():
    with patch("app.table", autospec=True) as mock_table:
        yield mock_table

@pytest.fixture
def client():
    from app import app
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_health_endpoint_schema(client, mock_dynamodb_table):
    """Test that the health endpoint returns standard json format."""
    mock_dynamodb_table.load.return_value = None
    response = client.get('/health')
    assert response.status_code == 200
    assert response.is_json

def test_index_route(client, mock_dynamodb_table):
    """Test that the index page loads."""
    mock_dynamodb_table.scan.return_value = {"Items": []}
    response = client.get('/')
    assert response.status_code == 200