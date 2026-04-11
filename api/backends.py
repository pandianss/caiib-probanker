from django.contrib.auth.backends import ModelBackend
from django.contrib.auth.models import User
from django.db.models import Q

class EmailOrUsernameModelBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        try:
            # single query, case-insensitive email check
            user = User.objects.get(Q(username=username) | Q(email__iexact=username))
        except User.MultipleObjectsReturned:
            user = User.objects.filter(Q(username=username) | Q(email__iexact=username)).first()
        except User.DoesNotExist:
            User().check_password(password)  # Constant-time dummy check
            return None
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
