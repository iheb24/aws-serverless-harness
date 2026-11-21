"""AWS SDK clients for the report_cron workload.

The only package layer allowed to import boto3 or botocore. Every client
subclasses ``BaseAwsClient`` and raises domain exceptions from
``report_cron.exceptions``.
"""
