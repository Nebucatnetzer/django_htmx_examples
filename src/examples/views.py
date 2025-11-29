from django.http import HttpResponse
from django.contrib.auth.views import LoginView
from django.urls import reverse_lazy
from django.views.generic import FormView
from examples.forms import RegisterForm


def index(request) -> HttpResponse:
    return HttpResponse("Base view")


class Login(LoginView):
    template_name = "registration/login.html"


class RegisterView(FormView):
    form_class = RegisterForm
    template_name = "registration/register.html"
    success_url = reverse_lazy("login")

    def form_valid(self, form):
        form.save()
        return super().form_valid(form)
