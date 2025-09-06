import numpy as np
import joblib
import pandas as pd

# Load artifacts
scaler = joblib.load("../models/scaler.pkl")
le = joblib.load("../models/label_encoder.pkl")
model = joblib.load("../models/log_reg_model.pkl")


def recommend_crop(N, P, K, temperature, humidity, ph, rainfall, top_k=3):
    """
    Recommend top-k crops based on soil and weather conditions.
    Args:
        N (float): Nitrogen content in soil
        P (float): Phosphorus content in soil
        K (float): Potassium content in soil
        temperature (float): Temperature in Celsius
        humidity (float): Relative humidity in percentage
        ph (float): pH value of the soil
        rainfall (float): Rainfall in mm
        
        top_k (int): Number of top crops to return
    
    Returns:
        List[str]: List of top-k recommended crop names
    """
    features = pd.DataFrame([{
        "N": N,
        "P": P,
        "K": K,
        "temperature": temperature,
        "humidity": humidity,
        "ph": ph,
        "rainfall": rainfall
    }])
    
    # scale
    features_scaled = scaler.transform(features)
    
    # get probability distribution
    probs = model.predict_proba(features_scaled)[0]
    
    # sort top-k
    top_k_idx = np.argsort(probs)[::-1][:top_k]
    top_k_labels = le.inverse_transform(top_k_idx)
    
    return list(top_k_labels)
