import os
from typing import Optional

import httpx


PEXELS_API_KEY = os.getenv("PEXELS_API_KEY")
PEXELS_SEARCH_URL = "https://api.pexels.com/v1/search"


def _clean_destination_name(destination_name: str) -> str:
    parts = [
        part.strip()
        for part in destination_name.split(",")
        if part.strip()
    ]

    if len(parts) >= 2:
        return f"{parts[0]} {parts[-1]}"

    return destination_name.strip()


def get_trip_photo_url(destination_name: str) -> Optional[str]:
    if not PEXELS_API_KEY:
        print("Brak PEXELS_API_KEY w pliku .env")
        return None

    clean_destination = _clean_destination_name(destination_name)

    params = {
        "query": f"{clean_destination} travel city",
        "per_page": 1,
        "orientation": "landscape",
    }

    headers = {
        "Authorization": PEXELS_API_KEY,
    }

    try:
        with httpx.Client(timeout=10.0) as client:
            response = client.get(
                PEXELS_SEARCH_URL,
                params=params,
                headers=headers,
            )

        if response.status_code != 200:
            print("PEXELS ERROR:", response.status_code, response.text)
            return None

        data = response.json()
        photos = data.get("photos", [])

        if not photos:
            return None

        src = photos[0].get("src", {})

        return (
            src.get("landscape")
            or src.get("large")
            or src.get("medium")
            or src.get("original")
        )

    except Exception as e:
        print("PEXELS REQUEST ERROR:", repr(e))
        return None