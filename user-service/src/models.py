from dataclasses import dataclass
from datetime import datetime
from typing import Optional
import uuid

@dataclass
class User:
    uuid: str
    name: str
    lastName: str
    email: str
    password: str
    document: str
    address: Optional[str] = None
    phone: Optional[str] = None
    image: Optional[str] = None
    createdAt: str = None
    
    def __post_init__(self):
        if self.createdAt is None:
            self.createdAt = datetime.utcnow().isoformat()
    
    def to_dict(self):
        return {
            'uuid': self.uuid,
            'name': self.name,
            'lastName': self.lastName,
            'email': self.email,
            'password': self.password,
            'document': self.document,
            'address': self.address,
            'phone': self.phone,
            'image': self.image,
            'createdAt': self.createdAt
        }

@dataclass
class Card:
    uuid: str
    user_id: str
    type: str  # DEBIT or CREDIT
    status: str = "PENDING"
    balance: float = 0.0
    createdAt: str = None
    
    def __post_init__(self):
        if self.createdAt is None:
            self.createdAt = datetime.utcnow().isoformat()
        if self.type == "DEBIT":
            self.status = "ACTIVATED"
    
    def to_dict(self):
        return {
            'uuid': self.uuid,
            'user_id': self.user_id,
            'type': self.type,
            'status': self.status,
            'balance': self.balance,
            'createdAt': self.createdAt
        }