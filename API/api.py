from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import uvicorn
from WeatherAPI.tool_weather import get_weather
from RecommendationEngine.src.tool_recommender import recommend_crop

app = FastAPI(
    title="Crop Recommendation API",
    description="API for crop recommendations based on soil and weather data",
    version="1.0.0"
)

class CropRecommendationRequest(BaseModel):
    lat: float
    long: float
    N: float
    P: float
    K: float
    Ph: float
    top_k: Optional[int] = 5

class CropRecommendationResponse(BaseModel):
    weather_data: dict
    recommended_crops: List[str]
    input_parameters: dict

@app.get("/")
async def root():
    return {"message": "Crop Recommendation API is running!"}

@app.post("/recommend_crops", response_model=CropRecommendationResponse)
async def recommend_crops_endpoint(request: CropRecommendationRequest):
    """
    Get crop recommendations based on location coordinates and soil parameters.
    
    Args:
        request: CropRecommendationRequest containing lat, long, N, P, K, Ph, and optional top_k
    
    Returns:
        CropRecommendationResponse with weather data and crop recommendations
    """
    try:
        # Step 1: Get weather data using lat and long
        weather_data = get_weather(lat=request.lat, lon=request.long)
        
        if not weather_data:
            raise HTTPException(status_code=400, detail="Failed to retrieve weather data")
        
        temperature = weather_data.get("temperature_c")
        humidity = weather_data.get("relative_humidity_percent")
        rainfall = weather_data.get("annual_precip_mm")
        
        if any(param is None for param in [temperature, humidity, rainfall]):
            raise HTTPException(
                status_code=400, 
                detail="Incomplete weather data retrieved. Missing temperature, humidity, or rainfall data."
            )

        recommended_crops = recommend_crop(
            N=request.N,
            P=request.P,
            K=request.K,
            temperature=temperature,
            humidity=humidity,
            ph=request.Ph,
            rainfall=rainfall,
            top_k=request.top_k
        )
        
        response = CropRecommendationResponse(
            weather_data=weather_data,
            recommended_crops=recommended_crops,
            input_parameters={
                "latitude": request.lat,
                "longitude": request.long,
                "nitrogen": request.N,
                "phosphorus": request.P,
                "potassium": request.K,
                "ph": request.Ph,
                "top_k": request.top_k
            }
        )
        
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)