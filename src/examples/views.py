from django.http import HttpResponse


def index(request) -> HttpResponse:
    return HttpResponse("Base view")
