from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage
from langchain.prompts import PromptTemplate
import os
from typing import Optional
# from Chatbot.prompt import competition_handling_prompt  # Commented out since we don't have this file
from dotenv import load_dotenv
import csv

load_dotenv()

def competition_handling_prompt(surrounding_crops, price_trends, recommended_crops):
    """
    Defines prompt for suggesting which crop to plant based on choices by surrounding farmers and current price trends.
    """
    return f"""
    You are the Krishi AI Sahayak, a helpful agricultural expert, who helps farmers make the best decision on what to plant.
    The key factor to keep in mind is even if a crop has a high expected revenue, if many farmers around you are planting it, the market will be saturated and you may not get the expected revenue.
    A few farmers around you have chosen to plant the following crops:
    {surrounding_crops}

    The current market prices for various crops are as follows:
    {price_trends}

    The farmer has been recommended the following crops to plant:
    {recommended_crops}

    Based on this information, choose which crop would be most profitable for the user to plant, and tell this to the user.
    Only return the recommended crop name, and a 2 line explanation.
    """

def read_village_crops(file_path):
    """
    Reads a CSV of neighbouring_crops and acres, 
    and returns an LLM-friendly summary and dictionary.
    """
    crop_dict = {}
    
    try:
        with open(file_path, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                crop = row['neighbouring_crops']
                acres = int(row['acres'])
                crop_dict[crop] = acres
    except FileNotFoundError:
        print(f"Warning: File {file_path} not found. Using sample data.")
        # Sample data for testing
        crop_dict = {"Rice": 100, "Wheat": 80, "Sugarcane": 60}
    except Exception as e:
        print(f"Error reading village crops: {e}")
        crop_dict = {"Rice": 100, "Wheat": 80, "Sugarcane": 60}
    
    # Create LLM-friendly summary
    summary_text = ", ".join([f"{acres} acres of {crop}" for crop, acres in crop_dict.items()])
    summary_text = "The village has " + summary_text + "."
    
    return summary_text, crop_dict

def read_crop_prices(file_path):
    """
    Reads a CSV of crops and total price earned per hectare,
    and returns an LLM-friendly summary and dictionary.
    """
    price_dict = {}
    
    try:
        with open(file_path, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                crop = row['CROP']
                price = int(row['Total Price earned in a hectare'])
                price_dict[crop] = price
    except FileNotFoundError:
        print(f"Warning: File {file_path} not found. Using sample data.")
        # Sample data for testing
        price_dict = {"Rice": 50000, "Wheat": 40000, "Maize": 35000}
    except Exception as e:
        print(f"Error reading crop prices: {e}")
        price_dict = {"Rice": 50000, "Wheat": 40000, "Maize": 35000}
    
    # Create LLM-friendly summary
    summary_text = ", ".join([f"{crop} earns {price} per hectare" for crop, price in price_dict.items()])
    summary_text = "Crop earnings per hectare are as follows: " + summary_text + "."
    
    return summary_text, price_dict

class SimpleGeminiChat:
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_API_KEY")
        if not self.api_key:
            print("Warning: GOOGLE_API_KEY not found in environment variables")

    def generate_response(self, suggested_crops: list, temperature=0.7):
        """
        Generate a single response from Gemini with improved error handling
        """
        try:
            # Read data with error handling
            village_data = read_village_crops("RecommendationEngine/artifacts/neighbours_data.csv")
            crop_price_data = read_crop_prices("RecommendationEngine/artifacts/crop_prices_yield_revenue.csv")

            # Create the prompt
            prompt_input = competition_handling_prompt(
                surrounding_crops=village_data[0],
                price_trends=crop_price_data[0],
                recommended_crops=", ".join(suggested_crops)
            )
            
            # Check if API key is available
            if not self.api_key:
                return "Error: Google API key not found. Please set GOOGLE_API_KEY in your .env file."
            
            llm = ChatGoogleGenerativeAI(
                model="gemini-2.0-flash-exp",  # Updated to a more stable model
                google_api_key=self.api_key,
                temperature=temperature,
                max_output_tokens=150  # Increased token limit
            )

            response = llm.invoke([HumanMessage(content=prompt_input)])
            return response.content
            
        except ImportError as e:
            return f"Import Error: {str(e)}. Make sure langchain_google_genai is installed: pip install langchain-google-genai"
        
        except Exception as e:
            print(f"Full error details: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()
            return f"Error: {str(e)}"

bot=SimpleGeminiChat()