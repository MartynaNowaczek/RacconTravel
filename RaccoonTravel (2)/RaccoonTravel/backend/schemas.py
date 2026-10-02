"""
Schematy danych Pydantic.
"""

from datetime import date
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, model_validator


class UserCreate(BaseModel):
    first_name: str = Field(
        ...,
        min_length=2,
        max_length=100,
        pattern=r"^[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+([ -][A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+)*$"
    )

    last_name: str = Field(
        ...,
        min_length=2,
        max_length=100,
        pattern=r"^[A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+([ -][A-Za-zĄĆĘŁŃÓŚŹŻąćęłńóśźż]+)*$"
    )

    username: str = Field(
        ...,
        min_length=3,
        max_length=100
    )

    email: EmailStr

    password: str = Field(
        ...,
        min_length=8,
        max_length=255
    )


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    username: str
    email: EmailStr

    profile_image_url: Optional[str] = None

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str
    confirm_password: str


class GoogleLoginRequest(BaseModel):
    id_token: str


class TripCreate(BaseModel):
    trip_name: str = Field(
        ...,
        min_length=2,
        max_length=255
    )

    origin_name: str = Field(
        ...,
        min_length=2,
        max_length=255
    )

    origin_place_id: Optional[str] = Field(
        default=None,
        max_length=255
    )

    destination_name: str = Field(
        ...,
        min_length=2,
        max_length=255
    )

    destination_place_id: Optional[str] = Field(
        default=None,
        max_length=255
    )

    start_date: date
    end_date: date

    @model_validator(mode="after")
    def validate_dates(self):
        if self.end_date < self.start_date:
            raise ValueError(
                "Data zakończenia nie może być wcześniejsza niż data rozpoczęcia."
            )

        return self


class TripResponse(BaseModel):
    id: int
    trip_name: str

    origin_name: str
    origin_place_id: Optional[str]

    destination_name: str
    destination_place_id: Optional[str]

    start_date: date
    end_date: date

    photo_url: Optional[str]
    status: str

    class Config:
        from_attributes = True
class FriendInvitationCreate(BaseModel):
    email: EmailStr


class FriendInvitationAccept(BaseModel):
    code: str = Field(
        ...,
        min_length=3,
        max_length=20,
    )


class FriendResponse(BaseModel):
    id: int
    first_name: str
    last_name: str
    username: str
    email: EmailStr
    profile_image_url: Optional[str] = None

    class Config:
        from_attributes = True