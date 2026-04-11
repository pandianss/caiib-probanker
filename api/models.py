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
    PAPER_CHOICES = [
        ('ABM', 'Advanced Bank Management'),
        ('BFM', 'Bank Financial Management'),
        ('ABFM', 'Advanced Business & Financial Management'),
        ('BRBL', 'Banking Regulations and Business Laws'),
        ('ELECTIVE', 'Elective Paper'),
    ]
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='progress')
    paper_code = models.CharField(max_length=20, choices=PAPER_CHOICES)
    current_score = models.FloatField(default=0.0)
    is_passed = models.BooleanField(default=False)
    last_activity = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('candidate', 'paper_code')

class SRSMetadata(models.Model):
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE)
    card_id = models.CharField(max_length=100)  # Refers to MognoDB document ID
    interval = models.IntegerField(default=1)  # Days
    ease_factor = models.FloatField(default=2.5)
    next_review = models.DateTimeField()
    repetition_count = models.IntegerField(default=0)

    class Meta:
        unique_together = ('candidate', 'card_id')

class ExamSession(models.Model):
    STATUS_CHOICES = [
        ('STARTED', 'Started'),
        ('COMPLETED', 'Completed'),
        ('ABANDONED', 'Abandoned'),
    ]
    candidate = models.ForeignKey(Candidate, on_delete=models.CASCADE, related_name='exam_sessions')
    paper_code = models.CharField(max_length=20)
    start_time = models.DateTimeField(auto_now_add=True)
    end_time = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='STARTED')
    final_score = models.FloatField(default=0.0)
    is_pass = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.candidate.user.username} - {self.paper_code} - {self.status}"

class QuestionAttempt(models.Model):
    session = models.ForeignKey(ExamSession, on_delete=models.CASCADE, related_name='attempts')
    question_id = models.CharField(max_length=100) # MongoDB Ref
    user_answer = models.TextField(null=True, blank=True)
    is_correct = models.BooleanField(default=False)
    marks_obtained = models.FloatField(default=0.0)
    time_taken_seconds = models.IntegerField(default=0)

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
