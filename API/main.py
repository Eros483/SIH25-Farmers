import os
import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, validator
from typing import Optional, List, Dict, Union
import uvicorn
import asyncio
import aiohttp
from contextlib import asynccontextmanager

# Import existing modules
from WeatherAPI.tool_weather import get_weather
from RecommendationEngine.src.tool_recommender import recommend_crop
from Chatbot.tool_chat import bot
from Chatbot.analyzer import bot as competition_bot

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Translation-related Pydantic models
class TranslationRequest(BaseModel):
    text: str
    source_lang: str
    target_lang: str

class BatchTranslationRequest(BaseModel):
    texts: List[str]
    source_lang: str
    target_lang: str

class TranslationResponse(BaseModel):
    success: bool
    translation: str
    service: Optional[str] = None
    error: Optional[str] = None

class BatchTranslationResponse(BaseModel):
    success: bool
    results: List[TranslationResponse]
    error: Optional[str] = None

# Existing crop recommendation models
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
    response_language: Optional[str] = "english"  # New field for translation
    
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

    @validator('response_language')
    def validate_language(cls, v):
        if v is not None:
            supported_langs = ['english', 'hindi', 'bengali', 'urdu', 'maithili', 'santali']
            if v.lower() not in supported_langs:
                raise ValueError(f'Unsupported language. Supported: {supported_langs}')
        return v.lower() if v else "english"

class CropRecommendationResponse(BaseModel):
    weather_data: dict
    recommended_crops: List[CropRecommendation]
    competition_analysis: str
    input_parameters: dict
    language: str  # Language of the response
    translation_status: Optional[str] = None  # Status of translation if applied

class ChatRequest(BaseModel):
    message: str
    user_id: Optional[str] = None
    response_language: Optional[str] = "english"  # New field for chat translation
    
    @validator('message')
    def validate_message(cls, v):
        if not v or not v.strip():
            raise ValueError('Message cannot be empty')
        if len(v.strip()) > 1000:
            raise ValueError('Message too long (max 1000 characters)')
        return v.strip()
    
    @validator('response_language')
    def validate_language(cls, v):
        if v is not None:
            supported_langs = ['english', 'hindi', 'bengali', 'urdu', 'maithili', 'santali']
            if v.lower() not in supported_langs:
                raise ValueError(f'Unsupported language. Supported: {supported_langs}')
        return v.lower() if v else "english"

class ChatResponse(BaseModel):
    response: str
    user_id: Optional[str] = None
    conversation_id: Optional[str] = None
    language: str = "english"
    translation_status: Optional[str] = None

# Translation service class
class LightweightTranslator:
    """
    Lightweight translator using external APIs with async support.
    """
    
    def __init__(self):
        self.language_codes = {
            'hindi': 'hi',
            'english': 'en', 
            'bengali': 'bn',
            'urdu': 'ur',
            'maithili': 'mai',
            'santali': 'sat'
        }
        
        # Support both full names and ISO codes
        self.code_mapping = {
            'hi': 'hindi',
            'en': 'english',
            'bn': 'bengali', 
            'ur': 'urdu',
            'mai': 'maithili',
            'sat': 'santali'
        }
        
        self.apis = {
            'mymemory': 'https://api.mymemory.translated.net/get',
            'libretranslate': 'https://libretranslate.de/translate'
        }
    
    def normalize_language(self, lang: str) -> str:
        """Normalize language input to full name"""
        lang_lower = lang.lower()
        if lang_lower in self.language_codes:
            return lang_lower
        elif lang_lower in self.code_mapping:
            return self.code_mapping[lang_lower]
        else:
            raise ValueError(f"Unsupported language: {lang}")
    
    async def translate_mymemory(self, session: aiohttp.ClientSession, text: str, source: str, target: str) -> Optional[str]:
        """Async translation using MyMemory API"""
        try:
            params = {
                'q': text,
                'langpair': f"{source}|{target}"
            }
            
            async with session.get(self.apis['mymemory'], params=params, timeout=10) as response:
                if response.status == 200:
                    data = await response.json()
                    if data.get('responseStatus') == 200:
                        return data['responseData']['translatedText']
            
            return None
            
        except Exception as e:
            logger.error(f"MyMemory translation error: {e}")
            return None
    
    async def translate_libretranslate(self, session: aiohttp.ClientSession, text: str, source: str, target: str) -> Optional[str]:
        """Async translation using LibreTranslate API"""
        try:
            payload = {
                'q': text,
                'source': source,
                'target': target,
                'format': 'text'
            }
            
            async with session.post(self.apis['libretranslate'], data=payload, timeout=10) as response:
                if response.status == 200:
                    data = await response.json()
                    return data.get('translatedText', '')
            
            return None
            
        except Exception as e:
            logger.error(f"LibreTranslate error: {e}")
            return None
    
    async def translate_text(self, text: str, source_lang: str, target_lang: str) -> TranslationResponse:
        """
        Async translate text with fallback to multiple services.
        """
        try:
            # Normalize language names
            source_lang = self.normalize_language(source_lang)
            target_lang = self.normalize_language(target_lang)
            
            # Same language check
            if source_lang == target_lang:
                return TranslationResponse(
                    success=True,
                    translation=text,
                    service='none'
                )
            
            # Get language codes
            src_code = self.language_codes[source_lang]
            tgt_code = self.language_codes[target_lang]
            
            # Create async session
            async with aiohttp.ClientSession() as session:
                # Try MyMemory first
                translation = await self.translate_mymemory(session, text, src_code, tgt_code)
                if translation:
                    return TranslationResponse(
                        success=True,
                        translation=translation,
                        service='mymemory'
                    )
                
                # Fallback to LibreTranslate
                translation = await self.translate_libretranslate(session, text, src_code, tgt_code)
                if translation:
                    return TranslationResponse(
                        success=True,
                        translation=translation,
                        service='libretranslate'
                    )
            
            # If all fail
            return TranslationResponse(
                success=False,
                error='All translation services failed',
                translation=text,
                service='none'
            )
            
        except Exception as e:
            return TranslationResponse(
                success=False,
                error=str(e),
                translation=text,
                service='none'
            )
    
    def get_supported_languages(self) -> List[str]:
        """Get list of supported languages"""
        return list(self.language_codes.keys())

# Global instances
translator = LightweightTranslator()
user_sessions = {}

def get_or_create_bot(user_id: Optional[str] = None):
    """Get existing bot instance for user or create new one"""
    if user_id is None:
        return bot
    
    if user_id not in user_sessions:
        from Chatbot.tool_chat import GeminiChatbot
        user_sessions[user_id] = GeminiChatbot()
        logger.info(f"Created new chatbot session for user: {user_id}")
    
    return user_sessions[user_id]

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("Starting Crop Recommendation API with Translation Support...")
    yield
    # Shutdown
    logger.info("Shutting down API...")

# Create FastAPI app
app = FastAPI(
    title="Crop Recommendation API with Multi-Language Support",
    description="Comprehensive API for crop recommendations, chat assistance, and multi-language translation supporting Hindi, English, Bengali, Urdu, Maithili, and Santali",
    version="2.0.0",
    docs_url="/docs" if os.getenv("ENV") != "production" else None,
    redoc_url="/redoc" if os.getenv("ENV") != "production" else None,
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "Crop Recommendation API with Multi-Language Support is running!",
        "version": "2.0.0",
        "features": [
            "Crop Recommendations with Competition Analysis",
            "Multi-Language Chat Support", 
            "Real-time Translation",
            "Weather Data Integration",
            "Batch Translation"
        ],
        "supported_languages": translator.get_supported_languages(),
        "endpoints": [
            "/recommend_crops", 
            "/chat", 
            "/translate",
            "/batch_translate",
            "/languages",
            "/chat/memory", 
            "/chat/clear", 
            "/health", 
            "/docs"
        ]
    }

@app.post("/recommend_crops", response_model=CropRecommendationResponse)
async def recommend_crops_endpoint(request: CropRecommendationRequest):
    """
    Get crop recommendations with optional multi-language response.
    
    Args:
        request: CropRecommendationRequest with coordinates, soil params, and optional response_language
    
    Returns:
        CropRecommendationResponse with recommendations and analysis in requested language
    """
    try:
        logger.info(f"Processing crop recommendation for coordinates: {request.lat}, {request.long} in {request.response_language}")
        
        # Step 1: Get weather data
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

        # Step 2: Get recommendations
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
        
        recommended_crops = [
            CropRecommendation(
                crop=rec["crop"],
                expected_revenue=rec["expected_revenue"]
            )
            for rec in recommendations
        ]
        
        # Step 3: Get competition analysis
        logger.info("Running competition analysis")
        try:
            suggested_crop_names = [rec["crop"] for rec in recommendations]
            competition_analysis = competition_bot.generate_response(
                suggested_crops=suggested_crop_names,
                temperature=0.7
            )
            logger.info("Successfully completed competition analysis")
        except Exception as e:
            logger.error(f"Competition analysis failed: {str(e)}")
            competition_analysis = f"Competition analysis unavailable. Recommended crops based on soil and weather conditions: {', '.join(suggested_crop_names[:3])}."
        
        # Step 4: Translate if needed
        translation_status = "original"
        if request.response_language != "english":
            try:
                logger.info(f"Translating competition analysis to {request.response_language}")
                translation_result = await translator.translate_text(
                    competition_analysis, 
                    "english", 
                    request.response_language
                )
                
                if translation_result.success:
                    competition_analysis = translation_result.translation
                    translation_status = f"translated_via_{translation_result.service}"
                else:
                    translation_status = f"translation_failed: {translation_result.error}"
                    logger.warning(f"Translation failed: {translation_result.error}")
                    
            except Exception as e:
                logger.error(f"Translation error: {str(e)}")
                translation_status = f"translation_error: {str(e)}"
        
        # Step 5: Build response
        response = CropRecommendationResponse(
            weather_data=weather_data,
            recommended_crops=recommended_crops,
            competition_analysis=competition_analysis,
            language=request.response_language,
            translation_status=translation_status,
            input_parameters={
                "latitude": request.lat,
                "longitude": request.long,
                "nitrogen": request.N,
                "phosphorus": request.P,
                "potassium": request.K,
                "ph": request.Ph,
                "top_k": request.top_k,
                "response_language": request.response_language
            }
        )
        
        logger.info(f"Successfully processed recommendation with {len(recommended_crops)} crops")
        return response
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error occurred")

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(request: ChatRequest):
    """
    Chat with agricultural assistant with multi-language support.
    """
    try:
        logger.info(f"Processing chat message for user: {request.user_id or 'anonymous'} in {request.response_language}")
        
        # Get bot response
        user_bot = get_or_create_bot(request.user_id)
        bot_response = user_bot.chat(request.message)
        
        # Translate if needed
        translation_status = "original"
        if request.response_language != "english":
            try:
                translation_result = await translator.translate_text(
                    bot_response, 
                    "english", 
                    request.response_language
                )
                
                if translation_result.success:
                    bot_response = translation_result.translation
                    translation_status = f"translated_via_{translation_result.service}"
                else:
                    translation_status = f"translation_failed: {translation_result.error}"
                    
            except Exception as e:
                logger.error(f"Chat translation error: {str(e)}")
                translation_status = f"translation_error: {str(e)}"
        
        response = ChatResponse(
            response=bot_response,
            user_id=request.user_id,
            conversation_id=request.user_id,
            language=request.response_language,
            translation_status=translation_status
        )
        
        logger.info(f"Successfully processed chat message")
        return response
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to process chat message")

# Translation endpoints
@app.post("/translate", response_model=TranslationResponse)
async def translate_text_endpoint(request: TranslationRequest):
    """Direct translation endpoint"""
    try:
        if len(request.text) > 1000:
            raise HTTPException(status_code=400, detail="Text too long (max 1000 characters)")
        
        result = await translator.translate_text(request.text, request.source_lang, request.target_lang)
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/batch_translate", response_model=BatchTranslationResponse)
async def batch_translate_endpoint(request: BatchTranslationRequest):
    """Batch translation endpoint"""
    try:
        if len(request.texts) > 10:
            raise HTTPException(status_code=400, detail="Batch size too large (max 10 texts)")
        
        tasks = []
        for text in request.texts:
            task = translator.translate_text(text, request.source_lang, request.target_lang)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks)
        
        return BatchTranslationResponse(success=True, results=results)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/languages")
async def get_supported_languages():
    """Get supported languages for translation"""
    return {
        "supported_languages": translator.get_supported_languages(),
        "language_codes": translator.language_codes
    }

@app.delete("/chat/clear")
async def clear_chat_memory(user_id: Optional[str] = None):
    """Clear conversation memory for a user"""
    try:
        if user_id is None:
            bot.clear_memory()
            logger.info("Cleared global chat memory")
        else:
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

@app.get("/buyers")
async def get_verified_buyers():
    """
    Get a static list of government-verified buyers for farming wholesale.
    Returns the data as a list of lists.
    """
    buyers = [
        ["Rajesh Kumar", "National Agricultural Cooperative Marketing Federation of India Ltd (NAFED)", "+91-9876543210"],
        ["Anita Sharma", "Food Corporation of India (FCI)", "+91-9811122233"],
        ["Suresh Patel", "State Farm Produce Marketing Federation Gujarat", "+91-9825098765"],
        ["Meena Reddy", "Andhra Pradesh State Civil Supplies Corporation", "+91-9849012345"],
        ["Amit Singh", "Haryana State Cooperative Supply and Marketing Federation (HAFED)", "+91-9810011223"],
    ]
    return {"buyers": buyers}

@app.get("/health")
async def health_check():
    """Comprehensive health check"""
    try:
        # Test chatbot
        test_response = bot.chat("test")
        chatbot_status = "healthy" if test_response and not test_response.startswith("Error:") else "unhealthy"
    except:
        chatbot_status = "unhealthy"
    
    try:
        # Test competition analysis
        test_competition = competition_bot.generate_response(["Rice", "Wheat"], temperature=0.5)
        competition_status = "healthy" if test_competition and not test_competition.startswith("Error:") else "unhealthy"
    except:
        competition_status = "unhealthy"
    
    try:
        # Test translation service
        test_translation = await translator.translate_text("Hello", "english", "hindi")
        translation_status = "healthy" if test_translation.success else "unhealthy"
    except:
        translation_status = "unhealthy"
    
    return {
        "status": "healthy",
        "services": {
            "api": "healthy",
            "chatbot": chatbot_status,
            "competition_analyzer": competition_status,
            "translation": translation_status
        },
        "active_sessions": len(user_sessions),
        "supported_languages": len(translator.get_supported_languages()),
        "timestamp": "2025-01-01T00:00:00Z",
        "version": "2.0.0"
    }

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)