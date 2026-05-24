from django.urls import path
from .views import RunSimulationView

urlpatterns = [
    path("simulation/run/", RunSimulationView.as_view(), name="run-simulation"),
]