"""AWS SDK clients for the order_worker workload.

The only package layer allowed to import boto3 or botocore. Every client
subclasses ``BaseAwsClient`` and raises domain exceptions from
``order_worker.exceptions``.
"""
