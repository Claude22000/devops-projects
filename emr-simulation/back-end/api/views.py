from django.shortcuts import render

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from simulation.model import RespiratoryDiseaseModel

class RunSimulationView(APIView):
    def post(self, request):
        population = int(request.data.get("population", 800))
        days = int(request.data.get("days", 365))
        width = int(request.data.get("width", 50))
        height = int(request.data.get("height", 50))
        initial_infected = int(request.data.get("initial_infected", 15))
        city = request.data.get("city", "Tijuana")

        model = RespiratoryDiseaseModel(
            population=population,
            width=width,
            height=height,
            initial_infected=initial_infected,
            city=city,
        )

        for _ in range(days):
            model.step()

        data = model.datacollector.get_model_vars_dataframe()

        return Response(
            {
                "city": city,
                "days": days,
                "population": population,
                "final_state": data.tail(1).to_dict(orient="records")[0],
                "daily_results": data.reset_index().to_dict(orient="records"),
            },
            status=status.HTTP_200_OK,
        )