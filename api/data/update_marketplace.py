import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from api.models import MarketplaceBundle, Bite, Candidate
from django.contrib.auth import get_user_model

User = get_user_model()
u = User.objects.filter(username='dev_user').first() or User.objects.first()
c, _ = Candidate.objects.get_or_create(user=u)

# 1. Update existing ABFM Module 1
paper_code_m1 = 'ABFM_Core_Management_Theories_and_Leadership'
bundle_m1 = MarketplaceBundle.objects.filter(paper_code=paper_code_m1).first()
if bundle_m1:
    bundle_m1.price = 149.00
    bundle_m1.title = 'ABFM Module 1: Core Management'
    bundle_m1.save()
    print(f"Updated {bundle_m1.title} to ₹149")

# 2. Create Full Subject Bundle
full_bundle, created = MarketplaceBundle.objects.get_or_create(
    paper_code='ABFM_FULL',
    defaults={
        'title': 'ABFM Comprehensive (All Modules)',
        'description': 'The complete 2026 ABFM curriculum covering all modules A, B, C, D.',
        'price': 399.00,
        'status': 'verified',
        'creator': c
    }
)

if not created:
    full_bundle.price = 399.00
    full_bundle.save()

# Link all bites to the full bundle
all_abfm_bites = Bite.objects.filter(paper_code=paper_code_m1)
full_bundle.bites.set(all_abfm_bites)

print(f"Marketplace Sync: {full_bundle.title} set to ₹399 with {all_abfm_bites.count()} bites.")
