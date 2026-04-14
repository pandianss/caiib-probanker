from django.db.models import Count, Avg, Q
from django.utils import timezone
from ..models import Bite, BiteAttempt, SRSMetadata, PaperProgress

class LearningService:
    @staticmethod
    def get_weak_areas(candidate, paper_code=None):
        """
        Identifies modules or chapters where accuracy is < 60% or 
        SRS status is predominantly 'WEAK'.
        """
        query = SRSMetadata.objects.filter(candidate=candidate, status='WEAK')
        if paper_code:
            # We need to link back to Bite to filter by paper_code
            bite_ids = Bite.objects.filter(paper_code=paper_code).values_list('bite_id', flat=True)
            query = query.filter(card_id__in=bite_ids)
        
        weak_bites = list(query.values_list('card_id', flat=True))
        
        # Analyze by module
        module_stats = BiteAttempt.objects.filter(candidate=candidate)
        if paper_code:
            module_stats = module_stats.filter(bite__paper_code=paper_code)
            
        stats = module_stats.values('bite__module').annotate(
            accuracy=Avg('is_correct', filter=Q(is_correct=True)),
            total=Count('id')
        ).filter(total__gt=5) # Only show areas with sufficient data
        
        critical_modules = [s['bite__module'] for s in stats if s['accuracy'] < 0.6]
        
        return {
            "weak_bite_ids": weak_bites,
            "critical_modules": critical_modules,
            "recommendation": "Focus on the critical modules list to improve your overall exam readiness score."
        }

    @staticmethod
    def calculate_exam_readiness(candidate, paper_code):
        """
        Predictive scoring for ELITE tier.
        Combines mastery %, SRS stability, and attempt consistency.
        """
        total_bites = Bite.objects.filter(paper_code=paper_code).count()
        if total_bites == 0: return 0.0
        
        mastered_count = SRSMetadata.objects.filter(
            candidate=candidate, 
            status='MASTERED',
            card_id__in=Bite.objects.filter(paper_code=paper_code).values_list('bite_id', flat=True)
        ).count()
        
        mastery_ratio = mastered_count / total_bites
        
        # Factor in recent accuracy (last 50 attempts)
        recent_attempts = BiteAttempt.objects.filter(
            candidate=candidate, 
            bite__paper_code=paper_code
        ).order_by('-attempted_at')[:50]
        
        if not recent_attempts:
            return round(mastery_ratio * 100, 2)
            
        recent_accuracy = sum(1 for a in recent_attempts if a.is_correct) / len(recent_attempts)
        
        # Weighting: 70% long-term mastery (SRS), 30% recent accuracy
        readiness = (mastery_ratio * 0.7) + (recent_accuracy * 0.3)
        
        return round(readiness * 100, 2)

    @staticmethod
    def get_remedial_drill(candidate, count=10):
        """
        Returns a set of 'WEAK' bites for targeted improvement.
        """
        weak_ids = SRSMetadata.objects.filter(
            candidate=candidate, 
            status='WEAK'
        ).order_by('next_review').values_list('card_id', flat=True)[:count]
        
        return Bite.objects.filter(bite_id__in=weak_ids)
