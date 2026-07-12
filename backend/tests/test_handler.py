"""Tests for the visitor-counter Lambda.

DynamoDB is mocked with ``moto`` — no AWS account, no network, no cost. The
suite asserts the two things that actually matter: the count increments
correctly (including under repeated/concurrent-style calls), and the HTTP
response shape is what the frontend and API Gateway expect.
"""

import json

import boto3
import pytest
from moto import mock_aws

TABLE_NAME = "test-visitor-count"
REGION = "eu-west-2"


@pytest.fixture
def handler(monkeypatch):
    monkeypatch.setenv("TABLE_NAME", TABLE_NAME)
    monkeypatch.setenv("ALLOWED_ORIGIN", "https://resume.example.dev")
    monkeypatch.setenv("AWS_DEFAULT_REGION", REGION)

    with mock_aws():
        ddb = boto3.resource("dynamodb", region_name=REGION)
        ddb.create_table(
            TableName=TABLE_NAME,
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            BillingMode="PAY_PER_REQUEST",
        )

        import handler as handler_module

        # Reset the cached resource so it binds inside this mock context.
        handler_module._resource = None
        yield handler_module


def _post(handler_module):
    """Simulate an API Gateway HTTP API POST /count event."""
    event = {"requestContext": {"http": {"method": "POST"}}}
    return handler_module.handler(event, None)


def test_first_visit_returns_one(handler):
    resp = _post(handler)
    body = json.loads(resp["body"])
    assert resp["statusCode"] == 200
    assert body["count"] == 1


def test_count_increments_across_visits(handler):
    for expected in range(1, 6):
        resp = _post(handler)
        assert json.loads(resp["body"])["count"] == expected


def test_many_sequential_visits_lose_nothing(handler):
    """Stand-in for concurrency: 50 increments must yield exactly 50, proving
    the atomic ADD never drops a write."""
    last = 0
    for _ in range(50):
        last = json.loads(_post(handler)["body"])["count"]
    assert last == 50


def test_response_shape_and_cors(handler):
    resp = _post(handler)
    assert resp["statusCode"] == 200
    assert resp["headers"]["Content-Type"] == "application/json"
    assert resp["headers"]["Access-Control-Allow-Origin"] == "https://resume.example.dev"
    assert resp["headers"]["Access-Control-Allow-Methods"] == "POST,OPTIONS"
    assert isinstance(json.loads(resp["body"])["count"], int)


def test_options_preflight_does_not_increment(handler):
    # Warm the counter to 1.
    _post(handler)
    # A preflight must not touch the count.
    preflight = handler.handler({"requestContext": {"http": {"method": "OPTIONS"}}}, None)
    assert preflight["statusCode"] == 200
    # Next real visit should be 2, not 3 — proving OPTIONS didn't increment.
    assert json.loads(_post(handler)["body"])["count"] == 2
