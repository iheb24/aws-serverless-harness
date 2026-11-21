"""Business logic for the report_cron workload.

Services receive client objects through dependency injection and never
import boto3, which keeps domain logic unit-testable without AWS.
"""
