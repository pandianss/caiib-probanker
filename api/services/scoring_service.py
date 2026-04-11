from ..models import ExamSession, PaperProgress, Candidate

class ScoringService:
    @staticmethod
    def calculate_session_result(session):
        attempts = session.attempts.all()
        total_marks = sum([a.marks_obtained for a in attempts])
        
        session.final_score = total_marks
        # Individual paper pass requirement is 45 marks
        session.is_pass = total_marks >= 45
        session.status = 'COMPLETED'
        session.save()
        
        # Update PaperProgress
        progress, _ = PaperProgress.objects.get_or_create(
            candidate=session.candidate,
            paper_code=session.paper_code
        )
        progress.current_score = total_marks
        progress.is_passed = session.is_pass
        progress.save()
        
        return session

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
