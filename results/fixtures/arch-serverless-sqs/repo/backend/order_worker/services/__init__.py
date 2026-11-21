"""Business logic for the order_worker workload.

Services receive client objects through dependency injection and never
import boto3, which keeps domain logic unit-testable without AWS.
"""
