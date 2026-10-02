"""
Router użytkowników.
"""

import os
import re
import secrets
import uuid

from datetime import datetime, timedelta
from fastapi.responses import Response
from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    UploadFile,
    status,
)

from fastapi.security import OAuth2PasswordRequestForm

from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

from sqlalchemy.orm import Session
from sqlalchemy import or_

from database import get_db

from models import (
    User,
    PasswordResetToken,
)

from schemas import (
    UserCreate,
    UserResponse,
    Token,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    GoogleLoginRequest,
)

from auth import (
    hash_password,
    verify_password,
    create_access_token,
    get_current_user,
    generate_reset_token,
    hash_reset_token,
)

from email_utils import send_password_reset_email


router = APIRouter(
    prefix="/users",
    tags=["users"]
)


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED
)
def register_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
):
    email = user_data.email.strip().lower()
    username = user_data.username.strip().lower()

    existing_email = (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )

    if existing_email:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Użytkownik z takim adresem e-mail już istnieje."
        )

    existing_username = (
        db.query(User)
        .filter(
            User.username == username
        )
        .first()
    )

    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ta nazwa użytkownika jest już zajęta."
        )

    new_user = User(
        first_name=user_data.first_name.strip(),
        last_name=user_data.last_name.strip(),
        username=username,
        email=email,
        hashed_password=hash_password(
            user_data.password
        )
    )

    db.add(
        new_user
    )

    db.commit()

    db.refresh(
        new_user
    )

    return new_user


@router.post(
    "/login",
    response_model=Token
)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    login_value = (
        form_data.username
        .strip()
        .lower()
    )

    user = (
        db.query(User)
        .filter(
            or_(
                User.email == login_value,
                User.username == login_value
            )
        )
        .first()
    )

    if not user or not verify_password(
        form_data.password,
        user.hashed_password
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy e-mail/login lub hasło.",
            headers={
                "WWW-Authenticate": "Bearer"
            }
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id)
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@router.get(
    "/me",
    response_model=UserResponse
)
def get_logged_user(
    current_user: User = Depends(
        get_current_user
    )
):
    return current_user


@router.post("/me/profile-image")
async def upload_profile_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    contents = await file.read()

    max_size = 5 * 1024 * 1024

    if len(contents) > max_size:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Zdjęcie może mieć maksymalnie 5 MB.",
        )

    content_type = file.content_type or ""

    allowed_types = {
        "image/jpeg",
        "image/png",
        "image/webp",
    }

    if content_type not in allowed_types:
        if contents.startswith(b"\xff\xd8\xff"):
            content_type = "image/jpeg"

        elif contents.startswith(b"\x89PNG\r\n\x1a\n"):
            content_type = "image/png"

        elif (
            len(contents) >= 12
            and contents[:4] == b"RIFF"
            and contents[8:12] == b"WEBP"
        ):
            content_type = "image/webp"

        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Dozwolone są tylko zdjęcia JPG, PNG oraz WEBP.",
            )

    current_user.profile_image = contents
    current_user.profile_image_content_type = content_type
    current_user.profile_image_url = None

    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return {
        "message": "Zdjęcie profilowe zostało zapisane.",
        "profile_image_url": f"/users/{current_user.id}/profile-image",
    }
@router.get("/{user_id}/profile-image")
def get_profile_image(
    user_id: int,
    db: Session = Depends(get_db),
):
    user = (
        db.query(User)
        .filter(User.id == user_id)
        .first()
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nie znaleziono użytkownika.",
        )

    if user.profile_image is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Użytkownik nie ma zdjęcia profilowego.",
        )

    return Response(
        content=user.profile_image,
        media_type=(
            user.profile_image_content_type
            or "image/jpeg"
        ),
    )
@router.post(
    "/forgot-password"
)
def forgot_password(
    data: ForgotPasswordRequest,
    db: Session = Depends(get_db)
):
    email = (
        data.email
        .strip()
        .lower()
    )

    success_message = {
        "message": (
            "Jeśli konto istnieje, "
            "wysłaliśmy link do resetowania hasła."
        )
    }

    user = (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )

    if not user:
        return success_message

    raw_token = (
        generate_reset_token()
    )

    token_hash = (
        hash_reset_token(
            raw_token
        )
    )

    reset_token = PasswordResetToken(
        user_id=user.id,
        token_hash=token_hash,
        expires_at=(
            datetime.utcnow()
            + timedelta(
                minutes=30
            )
        ),
        used=False
    )

    db.add(
        reset_token
    )

    db.commit()

    reset_url = os.getenv(
        "APP_RESET_URL",
        "http://localhost:8000/reset-password"
    )

    reset_link = (
        f"{reset_url}"
        f"?token={raw_token}"
    )

    print(
        "TOKEN RESETUJĄCY:",
        raw_token
    )

    print(
        "LINK RESETUJĄCY:",
        reset_link
    )

    send_password_reset_email(
        user.email,
        reset_link
    )

    return success_message


@router.post(
    "/reset-password"
)
def reset_password(
    data: ResetPasswordRequest,
    db: Session = Depends(get_db)
):
    if data.new_password != data.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Hasła nie są takie same."
        )

    if len(
        data.new_password
    ) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Hasło musi mieć co najmniej 8 znaków."
        )

    special_chars = (
        "!@#$%^&*()-_=+[]{};"
        ":'\",.<>?/\\|`~"
    )

    if not any(
        char in special_chars
        for char in data.new_password
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Hasło musi zawierać "
                "co najmniej jeden znak specjalny."
            )
        )

    token_hash = (
        hash_reset_token(
            data.token
        )
    )

    reset_token = (
        db.query(
            PasswordResetToken
        )
        .filter(
            PasswordResetToken.token_hash == token_hash,
            PasswordResetToken.used == False
        )
        .first()
    )

    if not reset_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nieprawidłowy token resetowania hasła."
        )

    if reset_token.expires_at < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Link resetowania hasła wygasł."
        )

    user = (
        db.query(User)
        .filter(
            User.id == reset_token.user_id
        )
        .first()
    )

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Nie znaleziono użytkownika."
        )

    user.hashed_password = (
        hash_password(
            data.new_password
        )
    )

    reset_token.used = True

    db.commit()

    return {
        "message": (
            "Hasło zostało zmienione. "
            "Możesz się teraz zalogować."
        )
    }


@router.post(
    "/google-login",
    response_model=Token
)
def google_login(
    google_data: GoogleLoginRequest,
    db: Session = Depends(get_db)
):
    google_client_id = os.getenv(
        "GOOGLE_CLIENT_ID"
    )

    if not google_client_id:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Brak konfiguracji GOOGLE_CLIENT_ID."
        )

    try:
        id_info = (
            google_id_token.verify_oauth2_token(
                google_data.id_token,
                google_requests.Request(),
                google_client_id
            )
        )

    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy token Google."
        )

    email = id_info.get(
        "email"
    )

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Konto Google nie zwróciło "
                "adresu e-mail."
            )
        )

    email_verified = (
        id_info.get(
            "email_verified"
        )
    )

    if email_verified is not True:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=(
                "Adres e-mail Google "
                "nie jest zweryfikowany."
            )
        )

    email = (
        email.strip()
        .lower()
    )

    user = (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )

    if user is None:
        first_name = (
            id_info.get(
                "given_name"
            )
            or "Google"
        )

        last_name = (
            id_info.get(
                "family_name"
            )
            or "User"
        )

        username_base = (
            email
            .split("@")[0]
            .lower()
        )

        username_base = re.sub(
            r"[^a-z0-9_]",
            "",
            username_base
        )

        if len(
            username_base
        ) < 3:
            username_base = (
                "googleuser"
            )

        username = username_base
        counter = 1

        while (
            db.query(User)
            .filter(
                User.username == username
            )
            .first()
        ):
            username = (
                f"{username_base}"
                f"{counter}"
            )

            counter += 1

        random_password = (
            secrets.token_urlsafe(
                32
            )
        )

        user = User(
            first_name=first_name,
            last_name=last_name,
            username=username,
            email=email,
            hashed_password=(
                hash_password(
                    random_password
                )
            )
        )

        db.add(
            user
        )

        db.commit()

        db.refresh(
            user
        )

    access_token = (
        create_access_token(
            data={
                "sub": str(
                    user.id
                )
            }
        )
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }