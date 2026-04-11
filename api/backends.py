from django.contrib.auth.backends import ModelBackend
from django.contrib.auth.models import User
from django.db.models import Q

class EmailOrUsernameModelBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        users = User.objects.filter(Q(username=username) | Q(email=username))
        for user in users:
            if user.check_password(password):
                return user
        return None
