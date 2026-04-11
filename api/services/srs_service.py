from datetime import datetime, timedelta
from django.utils import timezone
from ..models import SRSMetadata

class SRSService:
    @staticmethod
    def update_card(metadata, quality):
        """
        Implementation of SuperMemo-2 algorithm.
        quality: score from 0 to 5.
        0: Complete blackout.
        1: Incorrect response; the correct one remembered.
        2: Incorrect response; where the correct one seemed easy to recall.
        3: Correct response; recalled with serious difficulty.
        4: Correct response; after a hesitation.
        5: Perfect response.
        """
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
            
        metadata.next_review = timezone.now() + timedelta(days=metadata.interval)
        metadata.save()
        return metadata

    @staticmethod
    def get_due_cards(candidate):
        return SRSMetadata.objects.filter(candidate=candidate, next_review__lte=timezone.now())
