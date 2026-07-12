"""Visitor-counter Lambda.

Increments a single DynamoDB item atomically on each visit and returns the new
total. The atomic ``ADD`` is the whole point: two simultaneous visitors can
never both read N and both write N+1, so counts are never lost under
concurrency. There is no read-before-write anywhere in this function.
"""

import json
import os

import boto3

# Reused across warm invocations. Resolved lazily so tests can activate a mock
# (moto) *before* the client is created, and so a missing TABLE_NAME doesn't
# blow up at import time.
_resource = None


def _get_table():
    global _resource
    if _resource is None:
        _resource = boto3.resource("dynamodb")
    return _resource.Table(os.environ["TABLE_NAME"])


def _cors_headers():
    return {
        "Access-Control-Allow-Origin": os.environ.get("ALLOWED_ORIGIN", "*"),
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
        "Content-Type": "application/json",
    }


def _response(status, body):
    return {"statusCode": status, "headers": _cors_headers(), "body": json.dumps(body)}


def _method(event):
    """Extract the HTTP method from an API Gateway HTTP API (v2) event."""
    if not isinstance(event, dict):
        return "POST"
    return event.get("requestContext", {}).get("http", {}).get("method", "POST")


def handler(event, context=None):
    # CORS preflight — respond without touching the table.
    if _method(event) == "OPTIONS":
        return _response(200, {"ok": True})

    result = _get_table().update_item(
        Key={"id": "visits"},
        UpdateExpression="ADD #c :inc",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={":inc": 1},
        ReturnValues="UPDATED_NEW",
    )
    count = int(result["Attributes"]["count"])
    return _response(200, {"count": count})
