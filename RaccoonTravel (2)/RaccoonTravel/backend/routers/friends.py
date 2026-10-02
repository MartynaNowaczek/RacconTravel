import secrets
from datetime import datetime, timedelta

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
)

from sqlalchemy import or_
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from friend_email_utils import (
    send_friend_invitation_email,
)
from models import (
    FriendInvitation,
    Friendship,
    User,
)
from schemas import (
    FriendInvitationAccept,
    FriendInvitationCreate,
    FriendResponse,
)


router = APIRouter(
    prefix="/friends",
    tags=["friends"],
)


def _friendship_ids(
    user_a_id: int,
    user_b_id: int,
):
    """
    Zawsze zapisujemy mniejszy ID jako user1_id.
    Dzięki temu nie powstaną pary A-B oraz B-A.
    """

    return (
        min(user_a_id, user_b_id),
        max(user_a_id, user_b_id),
    )


def _friendship_exists(
    db: Session,
    user_a_id: int,
    user_b_id: int,
):
    user1_id, user2_id = _friendship_ids(
        user_a_id,
        user_b_id,
    )

    return (
        db.query(Friendship)
        .filter(
            Friendship.user1_id == user1_id,
            Friendship.user2_id == user2_id,
        )
        .first()
    )


def _generate_invitation_code(
    db: Session,
):
    alphabet = (
        "ABCDEFGHJKLMNPQRSTUVWXYZ"
        "23456789"
    )

    while True:
        random_part = "".join(
            secrets.choice(alphabet)
            for _ in range(6)
        )

        code = f"RT-{random_part}"

        existing = (
            db.query(FriendInvitation)
            .filter(
                FriendInvitation.code == code
            )
            .first()
        )

        if existing is None:
            return code


@router.post("/invitations")
def send_friend_invitation(
    data: FriendInvitationCreate,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):
    email = (
        data.email
        .strip()
        .lower()
    )

    receiver = (
        db.query(User)
        .filter(
            User.email == email
        )
        .first()
    )

    if receiver is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Nie znaleziono użytkownika o podanym adresie e-mail. "
                "Osoba musi najpierw utworzyć konto w RaccoonTravel, "
                "aby można było dodać ją do znajomych."
            ),
        )

    if receiver.id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Nie możesz wysłać zaproszenia do samego siebie."
            ),
        )

    existing_friendship = _friendship_exists(
        db,
        current_user.id,
        receiver.id,
    )

    if existing_friendship:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Ten użytkownik znajduje się już na Twojej liście znajomych."
            ),
        )

    existing_invitation = (
        db.query(FriendInvitation)
        .filter(
            FriendInvitation.sender_id
            == current_user.id,
            FriendInvitation.receiver_id
            == receiver.id,
            FriendInvitation.status
            == "pending",
            FriendInvitation.expires_at
            > datetime.utcnow(),
        )
        .first()
    )

    if existing_invitation:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "Zaproszenie do tego użytkownika zostało już wysłane."
            ),
        )

    code = _generate_invitation_code(
        db
    )

    invitation = FriendInvitation(
        sender_id=current_user.id,
        receiver_id=receiver.id,
        code=code,
        status="pending",
        expires_at=(
            datetime.utcnow()
            + timedelta(days=7)
        ),
    )

    db.add(
        invitation
    )

    db.flush()

    sender_name = (
        f"{current_user.first_name} "
        f"{current_user.last_name}"
    )

    try:
        send_friend_invitation_email(
            receiver_email=receiver.email,
            sender_name=sender_name,
            invitation_code=code,
        )
    except Exception:
        db.rollback()

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "Nie udało się wysłać wiadomości e-mail z zaproszeniem."
            ),
        )

    db.commit()

    return {
        "message": (
            "Zaproszenie zostało wysłane. "
            "Jeśli użytkownik przyjmie zaproszenie, "
            "pojawi się on na Twojej liście znajomych."
        )
    }


@router.post("/invitations/accept")
def accept_friend_invitation(
    data: FriendInvitationAccept,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):
    code = (
        data.code
        .strip()
        .upper()
    )

    invitation = (
        db.query(FriendInvitation)
        .filter(
            FriendInvitation.code == code,
            FriendInvitation.receiver_id
            == current_user.id,
            FriendInvitation.status
            == "pending",
        )
        .first()
    )

    if invitation is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Nie znaleziono aktywnego zaproszenia dla podanego kodu."
            ),
        )

    if invitation.expires_at < datetime.utcnow():
        invitation.status = "expired"

        db.commit()

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Kod zaproszenia wygasł."
            ),
        )

    existing_friendship = _friendship_exists(
        db,
        invitation.sender_id,
        invitation.receiver_id,
    )

    if existing_friendship:
        invitation.status = "accepted"
        db.commit()

        return {
            "message": (
                "Ten użytkownik znajduje się już na Twojej liście znajomych."
            )
        }

    user1_id, user2_id = _friendship_ids(
        invitation.sender_id,
        invitation.receiver_id,
    )

    friendship = Friendship(
        user1_id=user1_id,
        user2_id=user2_id,
    )

    db.add(
        friendship
    )

    invitation.status = "accepted"

    db.commit()

    return {
        "message": (
            "Zaproszenie zostało zaakceptowane. "
            "Użytkownik został dodany do Twoich znajomych."
        )
    }


@router.get(
    "",
    response_model=list[FriendResponse],
)
def get_friends(
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):
    friendships = (
        db.query(Friendship)
        .filter(
            or_(
                Friendship.user1_id
                == current_user.id,
                Friendship.user2_id
                == current_user.id,
            )
        )
        .all()
    )

    friend_ids = []

    for friendship in friendships:
        if friendship.user1_id == current_user.id:
            friend_ids.append(
                friendship.user2_id
            )
        else:
            friend_ids.append(
                friendship.user1_id
            )

    if not friend_ids:
        return []

    friends = (
        db.query(User)
        .filter(
            User.id.in_(friend_ids)
        )
        .order_by(
            User.username.asc()
        )
        .all()
    )

    return friends


@router.get(
    "/{user_id}",
    response_model=FriendResponse,
)
def get_friend_details(
    user_id: int,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):
    friendship = _friendship_exists(
        db,
        current_user.id,
        user_id,
    )

    if friendship is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Ten użytkownik nie znajduje się na Twojej liście znajomych."
            ),
        )

    friend = (
        db.query(User)
        .filter(
            User.id == user_id
        )
        .first()
    )

    if friend is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Nie znaleziono użytkownika."
            ),
        )

    return friend


@router.delete("/{user_id}")
def delete_friend(
    user_id: int,
    current_user: User = Depends(
        get_current_user
    ),
    db: Session = Depends(
        get_db
    ),
):
    friendship = _friendship_exists(
        db,
        current_user.id,
        user_id,
    )

    if friendship is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "Ten użytkownik nie znajduje się na Twojej liście znajomych."
            ),
        )

    db.delete(
        friendship
    )

    db.commit()

    return {
        "message": (
            "Użytkownik został usunięty ze znajomych."
        )
    }