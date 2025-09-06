import os
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
from typing import Optional, List
import uvicorn
from WeatherAPI.tool_weather import get_weather
from RecommendationEngine.src.tool_recommender import recommend_crop

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Crop Recommendation API",
    description="API for crop recommendations based on soil and weather data",
    version="1.0.0",
    docs_url="/docs" if os.getenv("ENV") != "production" else None,
    redoc_url="/redoc" if os.getenv("ENV") != "production" else None,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class CropRecommendationRequest(BaseModel):
    lat: float
    long: float
    N: float
    P: float
    K: float
    Ph: float
    top_k: Optional[int] = 5
    
    @validator('lat')
    def validate_latitude(cls, v):
        if not -90 <= v <= 90:
            raise ValueError('Latitude must be between -90 and 90')
        return v
    
    @validator('long')
    def validate_longitude(cls, v):
        if not -180 <= v <= 180:
            raise ValueError('Longitude must be between -180 and 180')
        return v
    
    @validator('Ph')
    def validate_ph(cls, v):
        if not 0 <= v <= 14:
            raise ValueError('pH must be between 0 and 14')
        return v
    
    @validator('top_k')
    def validate_top_k(cls, v):
        if v is not None and (v < 1 or v > 20):
            raise ValueError('top_k must be between 1 and 20')
        return v

class CropRecommendationResponse(BaseModel):
    weather_data: dict
    recommended_crops: List[str]
    input_parameters: dict

@app.get("/")
async def root():
    return {
        "message": "Crop Recommendation API is running!",
        "version": "1.0.0",
        "endpoints": ["/recommend_crops", "/health", "/docs"]
    }

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
        logger.info(f"Processing crop recommendation for coordinates: {request.lat}, {request.long}")
        
        # Step 1: Get weather data using lat and long
        weather_data = get_weather(lat=request.lat, lon=request.long)
        
        if not weather_data:
            logger.error("Failed to retrieve weather data")
            raise HTTPException(status_code=400, detail="Failed to retrieve weather data")
        
        temperature = weather_data.get("temperature_c")
        humidity = weather_data.get("relative_humidity_percent")
        rainfall = weather_data.get("annual_precip_mm")
        
        if any(param is None for param in [temperature, humidity, rainfall]):
            logger.error("Incomplete weather data retrieved")
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
        
        logger.info(f"Successfully processed recommendation with {len(recommended_crops)} crops")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error occurred")

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": "2025-01-01T00:00:00Z",  # You might want to use actual timestamp
        "version": "1.0.0"
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)