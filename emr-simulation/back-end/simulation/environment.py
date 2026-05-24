import random


class CityEnvironment:
    def __init__(self, city="Tijuana"):
        self.city = city
        self.season = "winter"
        self.temperature_celsius = 18
        self.climate_dryness = 0.50
        self.contamination = 0.35

    def update(self, day):
        day_of_year = day % 365

        if day_of_year < 80 or day_of_year >= 335:
            self.season = "winter"
            self.temperature_celsius = random.uniform(10, 20)
            self.climate_dryness = random.uniform(0.65, 0.9)
        elif day_of_year < 172:
            self.season = "spring"
            self.temperature_celsius = random.uniform(15, 25)
            self.climate_dryness = random.uniform(0.45, 0.7)
        elif day_of_year < 264:
            self.season = "summer"
            self.temperature_celsius = random.uniform(22, 34)
            self.climate_dryness = random.uniform(0.25, 0.55)
        else:
            self.season = "fall"
            self.temperature_celsius = random.uniform(14, 25)
            self.climate_dryness = random.uniform(0.45, 0.75)

        self.contamination = min(1.0, max(0.0, random.gauss(0.38, 0.12)))