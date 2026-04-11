import torch
import torch.nn as nn
import torch.nn.functional as F

class TAMKOTModel(nn.Module):
    def __init__(self, num_activities, num_concepts, embed_dim, hidden_dim):
        super(TAMKOTModel, self).__init__()
        self.activity_embed = nn.Embedding(num_activities, embed_dim)
        self.concept_embed = nn.Embedding(num_concepts, embed_dim)
        self.lstm = nn.LSTM(embed_dim * 2, hidden_dim, batch_first=True)
        self.fc = nn.Linear(hidden_dim, 1)

    def forward(self, activity_seq, concept_seq):
        a_emb = self.activity_embed(activity_seq)
        c_emb = self.concept_embed(concept_seq)
        x = torch.cat([a_emb, c_emb], dim=-1)
        out, _ = self.lstm(x)
        # We take the output of the last time step
        prob = torch.sigmoid(self.fc(out[:, -1, :]))
        return prob

class TAMKOTService:
    def __init__(self):
        # Initializing with dummy dimensions for bootstrap
        # Activities: 0: Video, 1: Question, 2: Reading
        # Concepts: Mapped to syllabus points
        self.model = TAMKOTModel(num_activities=5, num_concepts=100, embed_dim=32, hidden_dim=64)
        self.model.eval()
        self.weights_loaded = False
        
    def load_weights(self, path):
        import os
        if os.path.exists(path):
            try:
                self.model.load_state_dict(torch.load(path))
                self.model.eval()
                self.weights_loaded = True
            except Exception as e:
                print(f"Failed to load TAMKOT weights: {e}")
        else:
            print(f"TAMKOT weights file not found at {path}")

    def predict_passing_probability(self, activity_logs):
        """
        activity_logs: List of (activity_type, concept_id)
        """
        if not self.weights_loaded:
            return 0.5
            
        if not activity_logs:
            return 0.5 # Start with neutral probability
            
        with torch.no_grad():
            activities = torch.tensor([[log[0] for log in activity_logs]])
            concepts = torch.tensor([[log[1] for log in activity_logs]])
            prob = self.model(activities, concepts)
            return float(prob.item())

    def get_passing_thresholds(self, candidate_progress):
        """
        Returns a map showing how close the candidate is to 45 marks / 50% aggregate.
        """
        aggregate = sum([p['current_score'] for p in candidate_progress]) / 5.0
        details = {}
        for paper in candidate_progress:
            details[paper['paper_code']] = {
                "score": paper['current_score'],
                "needs": max(0, 45 - paper['current_score']),
                "status": "PASS" if paper['current_score'] >= 45 else "FAIL"
            }
        
        return {
            "aggregate": aggregate,
            "overall_status": "PASS" if aggregate >= 50 else "UNDER_PERFORMING",
            "details": details
        }
