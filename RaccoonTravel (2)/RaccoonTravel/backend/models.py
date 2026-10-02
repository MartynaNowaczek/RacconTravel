"""
Modele bazodanowe aplikacji RaccoonTravel.
"""

from datetime import datetime, date

from database import Base
from sqlalchemy import (
    Column,
    Integer,
    String,
    Boolean,
    DateTime,
    ForeignKey,
    Date,
    UniqueConstraint,
    LargeBinary,
)
from sqlalchemy.orm import relationship


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    profile_image_url = Column(String(1000), nullable=True)
    profile_image = Column(LargeBinary, nullable=True)
    profile_image_content_type = Column(String(100), nullable=True)

    username = Column(String(100), unique=True, nullable=False, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)

    hashed_password = Column(String(255), nullable=False)

    password_reset_tokens = relationship(
        "PasswordResetToken",
        back_populates="user",
        cascade="all, delete-orphan"
    )

    trips = relationship(
        "Trip",
        back_populates="user",
        cascade="all, delete-orphan"
    )


class PasswordResetToken(Base):
    __tablename__ = "password_reset_tokens"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)

    token_hash = Column(String(255), nullable=False, unique=True)
    expires_at = Column(DateTime, nullable=False)
    used = Column(Boolean, default=False, nullable=False)

    user = relationship(
        "User",
        back_populates="password_reset_tokens"
    )


class Trip(Base):
    __tablename__ = "trips"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    trip_name = Column(String(255), nullable=False)

    origin_name = Column(String(255), nullable=False)
    origin_place_id = Column(String(255), nullable=True)

    destination_name = Column(String(255), nullable=False)
    destination_place_id = Column(String(255), nullable=True)

    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)

    photo_url = Column(String(1000), nullable=True)

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False
    )

    user = relationship(
        "User",
        back_populates="trips"
    )

    @property
    def status(self) -> str:
        today = date.today()

        if self.start_date <= today <= self.end_date:
            return "current"

        if self.start_date > today:
            return "upcoming"

        return "archived"
class FriendInvitation(Base):
    """
    Zaproszenie do znajomych.
    """

    __tablename__ = "friend_invitations"

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    sender_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    receiver_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    code = Column(
        String(20),
        nullable=False,
        unique=True,
        index=True,
    )

    status = Column(
        String(20),
        nullable=False,
        default="pending",
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )

    expires_at = Column(
        DateTime,
        nullable=False,
    )


class Friendship(Base):
    """
    Relacja znajomości pomiędzy dwoma użytkownikami.
    """

    __tablename__ = "friendships"

    __table_args__ = (
        UniqueConstraint(
            "user1_id",
            "user2_id",
            name="uq_friendship_pair",
        ),
    )

    id = Column(
        Integer,
        primary_key=True,
        index=True,
    )

    user1_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    user2_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )