import pandas as pd
import ast

df = pd.read_csv("RecommendationEngine/artifacts/processed/cleaned_EcoCrop_DB.csv", encoding="cp1252")
df["COMNAME"] = df["COMNAME"].apply(ast.literal_eval)

def get_crop_ranges(crop_name: str):
    """
    Returns the pH, rainfall, and temperature ranges for a given crop name from EcoCrop DB.
    
    Parameters:
        crop_name (str): The crop to search for (exact match, case-insensitive)
        df (pd.DataFrame): The EcoCrop dataframe with 'COMNAME' as lists
    
    Returns:
        List[Dict]: Each dict contains ScientificName, COMNAME, PHMIN, PHMAX, RMIN, RMAX, TMIN, TMAX
    """
    crop_name = crop_name.lower().lstrip("_")  # normalize input
    
    def contains_only_crop(name_list):
        normalized = [name.lstrip("_").lower() for name in name_list]
        return crop_name in normalized
    
    mask = df["COMNAME"].apply(contains_only_crop)
    result_df = df[mask]
    
    # select relevant columns
    cols = ["ScientificName", "PHMIN", "PHMAX", "RMIN", "RMAX", "TMIN", "TMAX"]
    result_df = result_df[cols]
    
    # convert to list of dicts
    return result_df.to_dict(orient="records")
