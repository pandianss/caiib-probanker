import requests
import os
import json

# Configuration
API_URL = "http://127.0.0.1:8000/api/ingest/upload/"
ADMIN_SECRET = "dev_secret" # Adjust as per settings.py
CURRICULUM_DIR = "curriculum"

files_to_ingest = [
    "abm_batch_1.json",
    "bfm_batch_1.json",
    "brbl_batch_1.json"
]

print(f"Starting mass ingestion to {API_URL}...")

for filename in files_to_ingest:
    file_path = os.path.join(CURRICULUM_DIR, filename)
    if not os.path.exists(file_path):
        print(f"Skipping {filename}: File not found.")
        continue
        
    print(f"Ingesting {filename}...")
    
    with open(file_path, 'rb') as f:
        files = {'file': f}
        data = {
            'secret': ADMIN_SECRET,
            'auto_bundle': 'true'
        }
        
        try:
            response = requests.post(API_URL, data=data, files=files)
            if response.status_code == 200:
                print(f"SUCCESS: {filename} -> {response.json().get('count')} bites ingested.")
            else:
                print(f"FAILED: {filename} -> {response.status_code}: {response.text}")
        except Exception as e:
            print(f"ERROR: {filename} -> {str(e)}")

print("Mass ingestion complete.")
