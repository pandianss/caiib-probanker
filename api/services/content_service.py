import json
import os
from pymongo import MongoClient
from django.conf import settings

class ContentService:
    def __init__(self):
        self.client = None
        self.db = None
        self.use_fallback = False
        self.local_repo = {}
        
        # 1. Try MongoDB Connection
        try:
            self.client = MongoClient(settings.MONGO_URI, serverSelectionTimeoutMS=2000)
            self.client.server_info()
            self.db = self.client[settings.MONGO_DB_NAME]
        except Exception as e:
            print(f"MongoDB connection failed: {e}. Using JSON repositories.")
            self.use_fallback = True

        # 2. Always load JSON repositories as a core truth / dev fallback
        self._load_json_repositories()

    def _load_json_repositories(self):
        data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data')
        if not os.path.exists(data_dir):
            return

        for filename in os.listdir(data_dir):
            if filename.endswith('_content.json'):
                paper_code = filename.split('_')[0].upper()
                with open(os.path.join(data_dir, filename), 'r', encoding='utf-8') as f:
                    self.local_repo[paper_code] = json.load(f)
            elif filename == 'case_studies.json':
                with open(os.path.join(data_dir, filename), 'r', encoding='utf-8') as f:
                    self.case_studies = json.load(f)

    def get_case_studies(self, paper_code):
        return [cs for cs in self.case_studies if cs['paper_code'] == paper_code]

    def get_syllabus_structure(self):
        """Returns the high-level map of papers and modules based on the CAIIB roadmap."""
        return {
            "compulsory": [
                {
                    "code": "ABM", 
                    "name": "Advanced Bank Management", 
                    "modules": [
                        "Statistics & Numericals (Correlation, Regression)",
                        "Macroeconomics (GDP, Inflation, Fiscal Deficit)",
                        "HR & Organizational Behaviour",
                        "Credit Management (NPA, Provisioning)"
                    ]
                },
                {
                    "code": "BFM", 
                    "name": "Bank Financial Management", 
                    "modules": [
                        "Forex Arithmetic & FEMA",
                        "Risk Management (Basel, ICAAP)",
                        "Treasury Management & ALM",
                        "Balance Sheet Management"
                    ]
                },
                {
                    "code": "ABFM", 
                    "name": "Advanced Business & Financial Management", 
                    "modules": [
                        "Management Functions & Strategy",
                        "Capital Budgeting & WACC",
                        "Valuation & M&A Basics",
                        "Hybrid Finance & Convertibles"
                    ]
                },
                {
                    "code": "BRBL", 
                    "name": "Banking Regulations and Business Laws", 
                    "modules": [
                        "RBI & Banking Regulation Act",
                        "Negotiable Instruments & SARFAESI",
                        "Contract & Limitation Acts",
                        "KYC, AML & PMLA Compliance"
                    ]
                }
            ],
            "electives": [
                {"code": "RURAL", "name": "Rural Banking", "modules": ["Priority Sector Lending", "NABARD", "Agriculture Finance"]},
                {"code": "HRM", "name": "Human Resources Management", "modules": ["Industrial Relations", "Compensation", "Training ROI"]},
                {"code": "IT_DB", "name": "Information Technology & Digital Banking", "modules": ["Payment Systems", "Cyber Security", "Fintech"]},
                {"code": "RISK", "name": "Risk Management", "modules": ["VaR", "Stress Testing", "Internal Controls"]},
                {"code": "CENTRAL", "name": "Central Banking", "modules": ["Monetary Policy", "Liquidity Tools", "Payment Oversight"]}
            ]
        }

    def get_questions(self, paper_code, module_name=None):
        if not self.use_fallback and self.db:
            query = {"paper_code": paper_code}
            if module_name:
                query["module"] = module_name
            return list(self.db.questions.find(query))
        
        # Pull from JSON Repository
        if paper_code in self.local_repo:
            return self.local_repo[paper_code].get('questions', [])
            
        return []

    def get_flashcards(self, paper_code):
        if not self.use_fallback and self.db:
            return list(self.db.flashcards.find({"paper_code": paper_code}))
        
        # Pull from JSON Repository
        if paper_code in self.local_repo:
            return self.local_repo[paper_code].get('flashcards', [])
            
        return []
