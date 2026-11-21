"""Pydantic models for order data validation.

This module defines the schema for orders processed by the worker, ensuring
data integrity before persistence to DynamoDB.
"""

from pydantic import BaseModel, Field


class OrderRecord(BaseModel):
    """Schema for a validated order record.

    Attributes:
        order_id: Unique identifier for the order.
        user_id: Identifier of the user who placed the order.
        status: Current state of the order (e.g., 'pending', 'completed').
        total: Total monetary value of the order.
    """

    order_id: str = Field(..., min_length=1)
    user_id: str = Field(..., min_length=1)
    status: str = Field(default="pending")
    total: float = Field(..., ge=0.0)
