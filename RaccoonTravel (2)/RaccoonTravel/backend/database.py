"""
Konfiguracja połączenia z bazą danych PostgreSQL.

Plik odpowiada za utworzenie silnika bazy danych, sesji oraz bazowej klasy,
z której będą dziedziczyć modele tabel.
"""

import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()


def get_db():
    """
    Udostępnia sesję bazy danych dla endpointów FastAPI.
    Po zakończeniu działania endpointu sesja jest zamykana.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()