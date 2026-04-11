from ..models import PaperProgress, Candidate

class ScoringService:

    @staticmethod
    def check_aggregate_pass(candidate):
        """
        CAIIB Rule: 45 marks in each + 50% aggregate.
        """
        all_progress = candidate.progress.all()
        if all_progress.count() < 5:
            return False, "All 5 papers (4 compulsory + 1 elective) must be attempted."
        
        all_passed_min = all(p.current_score >= 45 for p in all_progress)
        aggregate = sum(p.current_score for p in all_progress)
        
        is_aggregate_pass = aggregate >= 250 # 50% of 500
        
        if all_passed_min and is_aggregate_pass:
            return True, "Congratulations! You have passed the CAIIB exam."
        elif not all_passed_min:
            return False, "Failed: One or more papers are below the 45-mark minimum."
        else:
            return False, f"Failed: Aggregate score ({aggregate}) is below the required 250 (50%)."
