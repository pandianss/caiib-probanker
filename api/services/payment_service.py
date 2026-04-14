import os
import hmac
import hashlib
import json
from django.utils import timezone
from ..models import SubscriptionPlan

class PaymentService:
    def __init__(self):
        self.key_id = os.getenv('RAZORPAY_KEY_ID', 'test_key_id')
        self.key_secret = os.getenv('RAZORPAY_KEY_SECRET', 'test_key_secret')

    def create_order(self, amount, currency='INR', receipt='ord_rcpt_001'):
        """
        In production, this would call the Razorpay API.
        """
        # Mocking for local dev with production-like structure
        order_id = f"order_{os.urandom(8).hex()}"
        return {
            "id": order_id,
            "amount": amount,
            "currency": currency,
            "receipt": receipt,
            "status": "created"
        }

    def verify_signature(self, razorpay_order_id, razorpay_payment_id, razorpay_signature):
        """
        Verifies the Razorpay payment signature to prevent payment spoofing.
        """
        if self.key_secret == 'test_key_secret':
            return True # Allow testing without real keys
            
        payload = f"{razorpay_order_id}|{razorpay_payment_id}"
        generated_signature = hmac.new(
            self.key_secret.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()
        
        return hmac.compare_digest(generated_signature, razorpay_signature)

    def activate_subscription(self, candidate, plan_type, duration_days=180):
        """
        Activates or upgrades a user's subscription.
        """
        plan, created = SubscriptionPlan.objects.get_or_create(candidate=candidate)
        
        # Define limits per tier
        TIER_LIMITS = {
            'FREE': 20,
            'PRO': 1000,
            'ELITE': 5000
        }
        
        plan.plan_type = plan_type
        plan.is_active = True
        plan.daily_bites_limit = TIER_LIMITS.get(plan_type, 20)
        plan.expiry_date = timezone.now().date() + timezone.timedelta(days=duration_days)
        plan.save()
        
        return plan

class ComplianceService:
    @staticmethod
    def log_consent(candidate, consent_type, version='1.0'):
        from ..models import ConsentLog
        # This would be called from a view
        return ConsentLog.objects.create(
            candidate=candidate,
            consent_type=consent_type,
            version=version
        )
