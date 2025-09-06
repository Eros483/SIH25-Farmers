# app.py - serve index.html + weather endpoint on port 8000 (no cors needed)
from flask import Flask, request, jsonify, send_from_directory
import requests
from datetime import datetime, timezone
import os
from flask_cors import CORS
app = Flask(__name__, static_url_path="")
CORS(app) 

OPEN_METEO_BASE = "https://api.open-meteo.com/v1/forecast"

def fetch_weather_open_meteo(lat: float, lon: float, timezone_str: str = "auto"):
    params = {
        "latitude": lat,
        "longitude": lon,
        "hourly": "relativehumidity_2m,precipitation",
        "current_weather": "true",
        "timezone": timezone_str,
    }
    r = requests.get(OPEN_METEO_BASE, params=params, timeout=20)
    r.raise_for_status()
    return r.json()

def pick_nearest_hourly(hourly_block, target_iso):
    # small pure-python matching without pandas
    times = hourly_block.get("time", [])
    if not times:
        return None, None
    # convert ISO strings to comparable prefix 'YYYY-MM-DDTHH'
    def hour_key(iso):
        return iso[:13]  # '2023-09-06T14'
    if isinstance(target_iso, str):
        target = target_iso
    else:
        target = target_iso.isoformat()
    tkey = hour_key(target)
    # find last time whose hour_key <= tkey
    idx = None
    for i, ts in enumerate(times):
        if hour_key(ts) <= tkey:
            idx = i
        else:
            break
    if idx is None:
        idx = 0
    rh_list = hourly_block.get("relativehumidity_2m", [])
    pr_list = hourly_block.get("precipitation", [])
    try:
        rh = float(rh_list[idx]) if idx < len(rh_list) else None
    except Exception:
        rh = None
    try:
        pr = float(pr_list[idx]) if idx < len(pr_list) else None
    except Exception:
        pr = None
    return rh, pr

@app.route("/")
@app.route("/index.html")
def index():
    # serve index.html from the same directory
    return send_from_directory(".", "index.html")

@app.route("/weather", methods=["POST"])
def weather():
    data = request.get_json(force=True, silent=True) or {}
    lat = data.get("lat")
    lon = data.get("lon")
    ts = data.get("timestamp")
    if lat is None or lon is None:
        return jsonify({"error":"missing lat or lon"}), 400
    if ts:
        try:
            requested_at = datetime.fromisoformat(ts)
        except Exception:
            requested_at = datetime.now(timezone.utc)
    else:
        requested_at = datetime.now(timezone.utc)

    try:
        raw = fetch_weather_open_meteo(lat, lon, timezone_str="auto")
    except Exception as e:
        return jsonify({"error":"open-meteo request failed","detail":str(e)}), 502

    current = raw.get("current_weather", {}) or {}
    temp = current.get("temperature")
    hourly = raw.get("hourly", {}) or {}
    rh, pr = pick_nearest_hourly(hourly, requested_at.isoformat())

    resp = {
        "temperature_c": float(temp) if temp is not None else None,
        "relative_humidity_percent": float(rh) if rh is not None else None,
        "precipitation_mm": float(pr) if pr is not None else None,
    }
    # log to console for debugging
    print("weather request:", resp)
    return jsonify(resp), 200

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    app.run(host="0.0.0.0", port=port, debug=True)
