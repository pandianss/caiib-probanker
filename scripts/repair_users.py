import os
import sys
import django

# Set up Django environment
sys.path.append(os.getcwd())
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import Candidate, SubscriptionPlan

def repair_users():
    print("--- Starting User Data Repair ---")
    candidates = Candidate.objects.all()
    created_count = 0
    
    for candidate in candidates:
        sub, created = SubscriptionPlan.objects.get_or_create(
            candidate=candidate,
            defaults={'plan_type': 'FREE', 'is_active': True}
        )
        if created:
            created_count += 1
            print(f"[REPAIRED] Linked SubscriptionPlan to {candidate.user.username}")
    
    print(f"\n[SUMMARY] Repaired {created_count} user(s). All users now have a valid tier.")

if __name__ == "__main__":
    repair_users()
