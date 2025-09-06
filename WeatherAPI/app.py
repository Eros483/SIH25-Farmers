#!/usr/bin/env python3
# app.py - simple weather client function using open-meteo

from datetime import datetime, timezone
import requests

OPEN_METEO_BASE = "https://api.open-meteo.com/v1/forecast"
API_PARAMS_TEMPLATE = {
    "hourly": "relativehumidity_2m,precipitation",
    "current_weather": "true",
    "timezone": "auto"
}

def _pick_nearest_hourly(hourly_block: dict, target_iso: str):
    times = hourly_block.get("time", [])
    if not times:
        return None, None
    def hour_key(iso: str) -> str: return iso[:13]
    target = target_iso if isinstance(target_iso, str) else target_iso.isoformat()
    tkey = hour_key(target)
    idx = None
    for i, ts in enumerate(times):
        if hour_key(ts) <= tkey:
            idx = i
        else:
            break
    if idx is None: idx = 0
    rh_list = hourly_block.get("relativehumidity_2m", [])
    pr_list = hourly_block.get("precipitation", [])
    rh, pr = None, None
    try: rh = float(rh_list[idx]) if idx < len(rh_list) else None
    except: pass
    try: pr = float(pr_list[idx]) if idx < len(pr_list) else None
    except: pass
    return rh, pr

def get_weather(lat: float, lon: float, timestamp: str | None = None) -> dict:
    if timestamp:
        try: requested_at = datetime.fromisoformat(timestamp)
        except Exception: requested_at = datetime.now(timezone.utc)
    else:
        requested_at = datetime.now(timezone.utc)

    params = {"latitude": lat, "longitude": lon, **API_PARAMS_TEMPLATE}
    r = requests.get(OPEN_METEO_BASE, params=params, timeout=25)
    r.raise_for_status()
    raw = r.json()

    current = raw.get("current_weather", {}) or {}
    temp = current.get("temperature")
    hourly = raw.get("hourly", {}) or {}
    rh, pr = _pick_nearest_hourly(hourly, requested_at.isoformat())

    return {
        "temperature_c": float(temp) if temp is not None else None,
        "relative_humidity_percent": float(rh) if rh is not None else None,
        "precipitation_mm": float(pr) if pr is not None else None,
    }

if __name__ == "__main__":
    print(get_weather(26.9124, 75.7873))  # jaipur
