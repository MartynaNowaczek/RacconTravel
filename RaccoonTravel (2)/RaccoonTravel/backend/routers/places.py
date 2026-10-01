from fastapi import APIRouter, HTTPException, Query
import httpx

router = APIRouter(
    prefix="/places",
    tags=["places"]
)


@router.get("/autocomplete")
async def autocomplete_places(
    input: str = Query(..., min_length=2, max_length=100)
):
    params = {
        "q": input,
        "limit": 6
    }

    headers = {
        "User-Agent": "RaccoonTravel/1.0"
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                "https://photon.komoot.io/api/",
                params=params,
                headers=headers
            )

            response.raise_for_status()

    except httpx.HTTPStatusError as e:
        print("PHOTON STATUS ERROR:", e.response.status_code, e.response.text)
        raise HTTPException(
            status_code=502,
            detail=f"Photon zwrócił błąd: {e.response.status_code}"
        )

    except httpx.RequestError as e:
        print("PHOTON REQUEST ERROR:", repr(e))
        raise HTTPException(
            status_code=502,
            detail=f"Nie udało się połączyć z Photon: {repr(e)}"
        )

    data = response.json()
    suggestions = []

    for feature in data.get("features", []):
        properties = feature.get("properties", {})
        geometry = feature.get("geometry", {})
        coordinates = geometry.get("coordinates", [])

        name = properties.get("name")
        country = properties.get("country")
        city = properties.get("city")
        state = properties.get("state")
        osm_type = properties.get("osm_type")
        osm_id = properties.get("osm_id")

        if not name or not osm_type or not osm_id:
            continue

        if len(coordinates) < 2:
            continue

        lon = coordinates[0]
        lat = coordinates[1]

        display_parts = [name]

        for part in [city, state, country]:
            if part and part not in display_parts:
                display_parts.append(part)

        display_name = ", ".join(display_parts)

        suggestions.append({
            "place_id": f"{osm_type}:{osm_id}",
            "name": display_name,
            "lat": lat,
            "lon": lon,
            "country": country,
            "city": city,
        })

    return suggestions