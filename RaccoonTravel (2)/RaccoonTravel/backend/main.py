"""
Główny plik aplikacji FastAPI.
"""

import os

from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from database import Base, engine

import models

from routers import users, trips, places


Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="RaccoonTravel API"
)


# Folder na zdjęcia profilowe
os.makedirs(
    "uploads/profile_images",
    exist_ok=True
)


# Udostępnienie plików przez API
app.mount(
    "/uploads",
    StaticFiles(
        directory="uploads"
    ),
    name="uploads"
)


app.include_router(
    users.router
)

app.include_router(
    trips.router
)

app.include_router(
    places.router
)


@app.get("/")
def read_root():
    return {
        "message": "Backend RaccoonTravel działa"
    }