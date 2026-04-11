import os

class PaymentService:
    def __init__(self):
        self.key_id = os.getenv('RAZORPAY_KEY_ID', 'test_key_id')
        self.key_secret = os.getenv('RAZORPAY_KEY_SECRET', 'test_key_secret')
        # In a real app, we'd use 'import razorpay'

    def create_order(self, amount, currency='INR', receipt='order_rcptid_11'):
        """
        Creates a Razorpay order.
        Amount should be in paise (e.g., 50000 for 500.00 INR)
        """
        # Mocking razorpay order creation
        return {
            "id": "order_EKZ9V6S6tO4s32",
            "amount": amount,
            "currency": currency,
            "receipt": receipt,
            "status": "created"
        }

class ComplianceService:
    @staticmethod
    def log_consent(candidate, consent_type, version='1.0'):
        """
        Logs user consent per DPDP Act 2023 requirements.
        """
        # This would save to a ConsentLog model
        print(f"Consent logged for {candidate.user.username}: {consent_type} v{version}")
        return True

    @staticmethod
    def get_data_summary(candidate):
        """
        Provides data minimization and transparency summary.
        """
        return {
            "pnp_collected": ["Personal Name", "Mobile Number", "Banking Professional Status"],
            "purpose": "Personalized CAIIB e-learning and SRS progression",
            "retention_period": "3 years (per CAIIB attempt cycle)",
            "rights": ["Access", "Correction", "Erasure", "Withdrawal of Consent"]
        }
