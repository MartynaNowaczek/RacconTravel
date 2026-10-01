from datetime import date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
from models import Trip, User
from schemas import TripCreate, TripResponse
from photo_service import get_trip_photo_url

router = APIRouter(
    prefix="/trips",
    tags=["trips"]
)


@router.post("", response_model=TripResponse, status_code=status.HTTP_201_CREATED)
def create_trip(
    trip_data: TripCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    new_trip = Trip(
        user_id=current_user.id,
        trip_name=trip_data.trip_name.strip(),
        origin_name=trip_data.origin_name.strip(),
        origin_place_id=trip_data.origin_place_id,
        destination_name=trip_data.destination_name.strip(),
        destination_place_id=trip_data.destination_place_id,
        start_date=trip_data.start_date,
        end_date=trip_data.end_date,
        photo_url=get_trip_photo_url(trip_data.destination_name)
    )

    db.add(new_trip)
    db.commit()
    db.refresh(new_trip)

    return new_trip


@router.get("", response_model=list[TripResponse])
def get_trips(
    search: Optional[str] = Query(default=None),
    trip_status: Optional[str] = Query(default=None, alias="status"),
    sort: str = Query(default="newest"),
    date_from: Optional[date] = Query(default=None),
    date_to: Optional[date] = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Trip).filter(Trip.user_id == current_user.id)

    if search:
        search_value = f"%{search.strip().lower()}%"

        query = query.filter(
            or_(
                func.lower(Trip.trip_name).like(search_value),
                func.lower(Trip.destination_name).like(search_value)
            )
        )

    today = date.today()

    if trip_status:
        if trip_status == "current":
            query = query.filter(
                Trip.start_date <= today,
                Trip.end_date >= today
            )
        elif trip_status == "upcoming":
            query = query.filter(Trip.start_date > today)
        elif trip_status == "archived":
            query = query.filter(Trip.end_date < today)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nieprawidłowy status wyjazdu."
            )

    if date_from:
        query = query.filter(Trip.end_date >= date_from)

    if date_to:
        query = query.filter(Trip.start_date <= date_to)

    if sort == "alpha":
        query = query.order_by(Trip.trip_name.asc())
    elif sort == "newest":
        query = query.order_by(Trip.start_date.desc())
    elif sort == "oldest":
        query = query.order_by(Trip.start_date.asc())
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Nieprawidłowy sposób sortowania."
        )

    return query.all()


@router.put("/{trip_id}", response_model=TripResponse)
def update_trip(
    trip_id: int,
    trip_data: TripCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trip = db.query(Trip).filter(
        Trip.id == trip_id,
        Trip.user_id == current_user.id
    ).first()

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wyjazd nie został znaleziony."
        )
    destination_changed = (
        trip.destination_name.strip().lower()
        != trip_data.destination_name.strip().lower()
    )

    trip.trip_name = trip_data.trip_name.strip()
    trip.origin_name = trip_data.origin_name.strip()
    trip.origin_place_id = trip_data.origin_place_id
    trip.destination_name = trip_data.destination_name.strip()
    trip.destination_place_id = trip_data.destination_place_id
    trip.start_date = trip_data.start_date
    trip.end_date = trip_data.end_date

    if destination_changed:
        trip.photo_url = get_trip_photo_url(trip_data.destination_name)

    db.commit()
    db.refresh(trip)

    return trip


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_trip(
    trip_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    trip = db.query(Trip).filter(
        Trip.id == trip_id,
        Trip.user_id == current_user.id
    ).first()

    if not trip:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Wyjazd nie został znaleziony."
        )

    db.delete(trip)
    db.commit()

    return Response(status_code=status.HTTP_204_NO_CONTENT)