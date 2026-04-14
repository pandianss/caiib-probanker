from datetime import datetime, timedelta
from django.utils import timezone
from ..models import SRSMetadata

class SRSService:
    @staticmethod
    def update_card(metadata, quality):
        """
        Implementation of SuperMemo-2 algorithm with pedagogical tagging.
        quality: score from 0 to 5.
        """
        # 1. Update Interval and Ease Factor (SM-2 Logic)
        if quality >= 3:
            if metadata.repetition_count == 0:
                metadata.interval = 1
            elif metadata.repetition_count == 1:
                metadata.interval = 6
            else:
                metadata.interval = int(round(metadata.interval * metadata.ease_factor))
            
            metadata.repetition_count += 1
            metadata.ease_factor = metadata.ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        else:
            metadata.repetition_count = 0
            metadata.interval = 1
            
        if metadata.ease_factor < 1.3:
            metadata.ease_factor = 1.3
            
        # 2. Update Pedagogical Status Tagging
        if quality < 3:
            metadata.status = 'WEAK'
        elif metadata.repetition_count == 0:
            metadata.status = 'NEW'
        elif metadata.repetition_count > 5 and metadata.ease_factor > 2.5:
            metadata.status = 'MASTERED'
        else:
            metadata.status = 'LEARNING'

        # 3. Save Next Review date
        metadata.next_review = timezone.now() + timedelta(days=metadata.interval)
        metadata.save()
        return metadata

    @staticmethod
    def get_due_cards(candidate):
        return SRSMetadata.objects.filter(candidate=candidate, next_review__lte=timezone.now())
