import os
import sys

# Make the Lambda source importable as `handler` from the tests.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lambda"))
