from django.db import models
from django.contrib.auth.models import User

class Candidate(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    selected_elective = models.CharField(max_length=100, choices=[
        ('RURAL', 'Rural Banking'),
        ('HRM', 'Human Resources Management'),
        ('IT_DB', 'Information Technology & Digital Banking'),
        ('RISK', 'Risk Management'),
        ('CENTRAL', 'Central Banking'),
    ], null=True, blank=True)
    attempts_count = models.PositiveIntegerField(default=0)
    start_date = models.DateField(auto_now_add=True)
    study_streak = models.IntegerField(default=0)
    last_study_date = models.DateField(null=True, blank=True)
    mobile_number = models.CharField(max_length=15, null=True, blank=True)

    def __str__(self):
        return self.user.username

class PaperProgress(models.Model):
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='progress')
    paper_code = models.CharField(max_length=20)
    current_score = models.FloatField(default=0.0)
    is_passed = models.BooleanField(default=False)
    last_activity = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('candidate', 'paper_code')

class SRSMetadata(models.Model):
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE)
    card_id = models.CharField(max_length=100)  # Refers to Bite.bite_id (e.g. 'abm_bite_001')
    interval = models.IntegerField(default=1)  # Days
    ease_factor = models.FloatField(default=2.5)
    next_review = models.DateTimeField()
    repetition_count = models.IntegerField(default=0)

    class Meta:
        unique_together = ('candidate', 'card_id')

class MarketplaceBundle(models.Model):
    STATUS_CHOICES = [('draft', 'Draft'), ('pending', 'Pending Approval'), ('verified', 'Verified')]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    creator = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='created_bundles')
    paper_code = models.CharField(max_length=20)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='draft')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.title} by {self.creator.user.username}"

class BundleAccess(models.Model):
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='accessed_bundles')
    bundle = models.ForeignKey(MarketplaceBundle, on_delete=models.CASCADE)
    purchased_at = models.DateTimeField(auto_now_add=True)
    transaction_id = models.CharField(max_length=255, blank=True)

    class Meta:
        unique_together = ('candidate', 'bundle')

class Bite(models.Model):
    DIFFICULTY_CHOICES = [('easy','Easy'), ('medium','Medium'), ('hard','Hard')]
    TYPE_CHOICES = [('conceptual','Conceptual'), ('numerical','Numerical'), ('regulatory','Regulatory')]

    bite_id       = models.CharField(max_length=50, unique=True)
    paper_code    = models.CharField(max_length=20)
    module        = models.CharField(max_length=100)
    chapter       = models.CharField(max_length=200, default='General')
    title         = models.CharField(max_length=200)
    concept       = models.TextField()
    example       = models.TextField(blank=True)
    formula       = models.CharField(max_length=300, blank=True)
    question_text = models.TextField()
    question_type = models.CharField(max_length=20, choices=[('mcq','MCQ'),('numerical','Numerical')])
    options       = models.JSONField(null=True, blank=True)
    answer        = models.CharField(max_length=200)
    tolerance     = models.FloatField(default=0.0)
    explanation   = models.TextField()
    difficulty    = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    bite_type     = models.CharField(max_length=20, choices=TYPE_CHOICES, default='conceptual')
    estimated_minutes = models.IntegerField(default=5)
    tags          = models.JSONField(default=list)
    bundle        = models.ForeignKey(MarketplaceBundle, on_delete=models.SET_NULL, null=True, blank=True, related_name='bites')
    is_free       = models.BooleanField(default=False)
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['paper_code', 'module', 'bite_id']

class BiteAttempt(models.Model):
    candidate        = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='bite_attempts')
    bite             = models.ForeignKey(Bite, on_delete=models.CASCADE)
    user_answer      = models.CharField(max_length=300)
    is_correct       = models.BooleanField()
    time_taken_seconds = models.IntegerField(default=0)
    attempted_at     = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-attempted_at']

class UserActivity(models.Model):
    ACTIVITY_CHOICES = [(0,'video'),(1,'question'),(2,'flashcard'),(3,'reading')]
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE)
    activity_type = models.IntegerField(choices=ACTIVITY_CHOICES)
    concept_id = models.IntegerField()  # maps to syllabus concept index
    timestamp = models.DateTimeField(auto_now_add=True)

class ConsentLog(models.Model):
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE)
    consent_type = models.CharField(max_length=100)
    version = models.CharField(max_length=20, default='1.0')
    timestamp = models.DateTimeField(auto_now_add=True)
    ip_address = models.GenericIPAddressField(null=True)

class SubscriptionPlan(models.Model):
    candidate = models.OneToOneField(Candidate, on_delete=models.CASCADE)
    is_active = models.BooleanField(default=False)
    plan_type = models.CharField(max_length=50, default='FREE')
    expiry_date = models.DateField(null=True, blank=True)
    razorpay_order_id = models.CharField(max_length=100, blank=True)
