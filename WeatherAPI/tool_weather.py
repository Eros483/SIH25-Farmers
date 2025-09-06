#!/usr/bin/env python3
# app.py - simplified weather client (Open-Meteo)
# returns temperature, humidity, and year-to-date rainfall (mm)

from datetime import datetime, timezone
import requests
from typing import Optional

OPEN_METEO_BASE = "https://api.open-meteo.com/v1/forecast"
OPEN_METEO_ARCHIVE = "https://archive-api.open-meteo.com/v1/archive"

# request only what we need
API_PARAMS_TEMPLATE = {
    "hourly": "relativehumidity_2m",
    "current_weather": "true",
    "timezone": "auto"
}

def _pick_nearest_hourly(hourly_block: dict, target_iso: str) -> Optional[float]:
    """pick nearest hourly relative humidity"""
    times = hourly_block.get("time", [])
    if not times:
        return None

    def hour_key(iso: str) -> str: return iso[:13]
    target = target_iso if isinstance(target_iso, str) else target_iso.isoformat()
    tkey = hour_key(target)

    idx = None
    for i, ts in enumerate(times):
        if hour_key(ts) <= tkey:
            idx = i
        else:
            break
    if idx is None:
        idx = 0

    rh_list = hourly_block.get("relativehumidity_2m", [])
    try:
        return float(rh_list[idx]) if idx < len(rh_list) else None
    except Exception:
        return None

def fetch_year_to_date_precip(lat: float, lon: float, year: int) -> Optional[float]:
    """fetch daily precipitation sums from Jan 1 of given year to today, return total mm"""
    start = f"{year}-01-01"
    today = datetime.now().date()
    end = today.strftime("%Y-%m-%d")

    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start,
        "end_date": end,
        "daily": "precipitation_sum",
        "timezone": "UTC",
    }
    try:
        r = requests.get(OPEN_METEO_ARCHIVE, params=params, timeout=40)
        r.raise_for_status()
        j = r.json()
        daily = j.get("daily", {}) or {}
        precip_list = daily.get("precipitation_sum", []) or []
        return sum(float(v) for v in precip_list if v is not None)
    except Exception as e:
        print("archive fetch failed:", e)
        return None

def get_weather(lat: float, lon: float, timestamp: Optional[str] = None) -> dict:
    """
    returns:
      {
        "temperature_c": float|None,
        "relative_humidity_percent": float|None,
        "annual_precip_mm": float|None
      }
    """
    # pick timestamp or now
    if timestamp:
        try:
            req_time = datetime.fromisoformat(timestamp)
        except Exception:
            req_time = datetime.now(timezone.utc)
    else:
        req_time = datetime.now(timezone.utc)

    year = req_time.year

    # fetch current + humidity
    try:
        params = {"latitude": lat, "longitude": lon, **API_PARAMS_TEMPLATE}
        r = requests.get(OPEN_METEO_BASE, params=params, timeout=25)
        r.raise_for_status()
        raw = r.json()
    except Exception as e:
        return {"error": "open-meteo request failed", "detail": str(e)}

    current = raw.get("current_weather", {}) or {}
    temp = current.get("temperature")
    hourly = raw.get("hourly", {}) or {}
    rh = _pick_nearest_hourly(hourly, req_time.isoformat())

    annual = fetch_year_to_date_precip(lat, lon, year)

    return {
        "temperature_c": float(temp) if temp is not None else None,
        "relative_humidity_percent": float(rh) if rh is not None else None,
        "annual_precip_mm": float(annual) if annual is not None else None,
    }

# demo
if __name__ == "__main__":
    print(get_weather(26.9124, 75.7873))  # jaipur
