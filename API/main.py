import os
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
from typing import Optional, List, Dict, Union
import uvicorn
from WeatherAPI.tool_weather import get_weather
from RecommendationEngine.src.tool_recommender import recommend_crop
from Chatbot.tool_chat import bot
from Chatbot.analyzer import bot as competition_bot  # Import the competition analysis bot

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Crop Recommendation & Chat API",
    description="API for crop recommendations based on soil and weather data, with integrated chatbot and competition analysis",
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

class CropRecommendation(BaseModel):
    crop: str
    expected_revenue: float

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
    recommended_crops: List[CropRecommendation]
    competition_analysis: str  # New field for LLM analysis
    input_parameters: dict

class ChatRequest(BaseModel):
    message: str
    user_id: Optional[str] = None  # Optional user identification for session management
    
    @validator('message')
    def validate_message(cls, v):
        if not v or not v.strip():
            raise ValueError('Message cannot be empty')
        if len(v.strip()) > 1000:
            raise ValueError('Message too long (max 1000 characters)')
        return v.strip()

class ChatResponse(BaseModel):
    response: str
    user_id: Optional[str] = None
    conversation_id: Optional[str] = None

class ChatMemoryResponse(BaseModel):
    memory: str
    user_id: Optional[str] = None

# Store for managing multiple user sessions (in production, use Redis or database)
user_sessions = {}

def get_or_create_bot(user_id: Optional[str] = None):
    """Get existing bot instance for user or create new one"""
    if user_id is None:
        return bot  # Use global bot instance for anonymous users
    
    if user_id not in user_sessions:
        from Chatbot.tool_chat import GeminiChatbot
        user_sessions[user_id] = GeminiChatbot()
        logger.info(f"Created new chatbot session for user: {user_id}")
    
    return user_sessions[user_id]

@app.get("/")
async def root():
    return {
        "message": "Crop Recommendation & Chat API with Competition Analysis is running!",
        "version": "1.0.0",
        "endpoints": [
            "/recommend_crops", 
            "/chat", 
            "/chat/memory", 
            "/chat/clear", 
            "/health", 
            "/docs"
        ]
    }

@app.post("/recommend_crops", response_model=CropRecommendationResponse)
async def recommend_crops_endpoint(request: CropRecommendationRequest):
    """
    Get crop recommendations based on location coordinates and soil parameters,
    with competition analysis from neighboring farmers.
    
    Args:
        request: CropRecommendationRequest containing lat, long, N, P, K, Ph, and optional top_k
    
    Returns:
        CropRecommendationResponse with weather data, crop recommendations with expected revenue,
        and competition analysis advice
    """
    try:
        logger.info(f"Processing crop recommendation for coordinates: {request.lat}, {request.long}")
        
        # Step 1: Get weather data using lat and long
        weather_data = get_weather(lat=request.lat, lon=request.long, year=2024)
        
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

        # Step 2: Get recommendations (returns list of dicts with crop and expected_revenue)
        recommendations = recommend_crop(
            N=request.N,
            P=request.P,
            K=request.K,
            temperature=temperature,
            humidity=humidity,
            ph=request.Ph,
            rainfall=rainfall,
            top_k=request.top_k
        )
        
        # Convert to CropRecommendation objects
        recommended_crops = [
            CropRecommendation(
                crop=rec["crop"],
                expected_revenue=rec["expected_revenue"]
            )
            for rec in recommendations
        ]
        
        # Step 3: Run competition analysis on recommended crops
        logger.info("Running competition analysis on recommended crops")
        try:
            # Extract crop names for analysis
            suggested_crop_names = [rec["crop"] for rec in recommendations]
            
            # Get competition analysis from the analyzer bot
            competition_analysis = competition_bot.generate_response(
                suggested_crops=suggested_crop_names,
                temperature=0.7
            )
            
            logger.info("Successfully completed competition analysis")
            
        except Exception as e:
            logger.error(f"Competition analysis failed: {str(e)}")
            # Provide fallback analysis if the competition bot fails
            competition_analysis = f"Competition analysis unavailable. Recommended crops based on soil and weather conditions: {', '.join(suggested_crop_names[:3])}."
        
        # Step 4: Build response
        response = CropRecommendationResponse(
            weather_data=weather_data,
            recommended_crops=recommended_crops,
            competition_analysis=competition_analysis,
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
        
        logger.info(f"Successfully processed recommendation with {len(recommended_crops)} crops and competition analysis")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error occurred")

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Chat with the Gemini-powered agricultural assistant.
    
    Args:
        request: ChatRequest containing message and optional user_id
    
    Returns:
        ChatResponse with the bot's response
    """
    try:
        logger.info(f"Processing chat message for user: {request.user_id or 'anonymous'}")
        
        # Get or create bot instance for this user
        user_bot = get_or_create_bot(request.user_id)
        
        # Get response from chatbot
        bot_response = user_bot.chat(request.message)
        
        response = ChatResponse(
            response=bot_response,
            user_id=request.user_id,
            conversation_id=request.user_id  # Using user_id as conversation_id for simplicity
        )
        
        logger.info(f"Successfully processed chat message for user: {request.user_id or 'anonymous'}")
        return response
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to process chat message")

@app.delete("/chat/clear")
async def clear_chat_memory(user_id: Optional[str] = None):
    """
    Clear the conversation memory for a user.
    
    Args:
        user_id: Optional user identifier
    
    Returns:
        Success message
    """
    try:
        if user_id is None:
            # Clear global bot memory
            bot.clear_memory()
            logger.info("Cleared global chat memory")
        else:
            # Clear specific user's memory
            if user_id in user_sessions:
                user_sessions[user_id].clear_memory()
                logger.info(f"Cleared chat memory for user: {user_id}")
            else:
                logger.info(f"No existing session found for user: {user_id}")
        
        return {
            "message": "Chat memory cleared successfully",
            "user_id": user_id,
            "timestamp": "2025-01-01T00:00:00Z"
        }
        
    except Exception as e:
        logger.error(f"Error clearing chat memory: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to clear chat memory")

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    try:
        # Test chatbot connectivity
        test_response = bot.chat("test")
        chatbot_status = "healthy" if test_response and not test_response.startswith("Error:") else "unhealthy"
    except:
        chatbot_status = "unhealthy"
    
    try:
        # Test competition analysis bot
        test_competition = competition_bot.generate_response(["Rice", "Wheat"], temperature=0.5)
        competition_status = "healthy" if test_competition and not test_competition.startswith("Error:") else "unhealthy"
    except:
        competition_status = "unhealthy"
    
    return {
        "status": "healthy",
        "services": {
            "api": "healthy",
            "chatbot": chatbot_status,
            "competition_analyzer": competition_status
        },
        "active_sessions": len(user_sessions),
        "timestamp": "2025-01-01T00:00:00Z",
        "version": "1.0.0"
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)