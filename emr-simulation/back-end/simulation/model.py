import random
from mesa import Model
from mesa.space import MultiGrid
from mesa.datacollection import DataCollector

from simulation.agents import PersonAgent
from simulation.disease import HealthState, BASE_TRANSMISSION
from simulation.environment import CityEnvironment


class RespiratoryDiseaseModel(Model):
    def __init__(
        self,
        population=800,
        width=50,
        height=50,
        initial_infected=15,
        city="Tijuana",
    ):
        super().__init__()

        self.population = population
        self.grid = MultiGrid(width, height, torus=True)
        self.environment = CityEnvironment(city)
        self.day = 0

        for _ in range(population):
            agent = PersonAgent(self, self.generate_age())
            x = self.random.randrange(width)
            y = self.random.randrange(height)
            self.grid.place_agent(agent, (x, y))

        infected_agents = random.sample(list(self.agents), initial_infected)

        for agent in infected_agents:
            agent.health_state = random.choice([
                HealthState.INFECTED_FLU,
                HealthState.INFECTED_COVID,
                HealthState.INFECTED_COLD,
            ])

        self.datacollector = DataCollector(
            model_reporters={
                "Susceptible": lambda m: m.count_state(HealthState.SUSCEPTIBLE),
                "Flu": lambda m: m.count_state(HealthState.INFECTED_FLU),
                "Covid": lambda m: m.count_state(HealthState.INFECTED_COVID),
                "Cold": lambda m: m.count_state(HealthState.INFECTED_COLD),
                "Recovered": lambda m: m.count_state(HealthState.RECOVERED),
                "Season": lambda m: m.environment.season,
                "Temperature": lambda m: m.environment.temperature_celsius,
                "Contamination": lambda m: m.environment.contamination,
            }
        )

    def generate_age(self):
        roll = random.random()

        if roll < 0.22:
            return random.randint(0, 17)
        if roll < 0.67:
            return random.randint(18, 49)
        if roll < 0.87:
            return random.randint(50, 64)

        return random.randint(65, 90)

    def get_transmission_probability(self, disease, infected_agent, target_agent):
        base_probability = BASE_TRANSMISSION[disease]

        season_multiplier = {
            "winter": 1.45,
            "spring": 1.05,
            "summer": 0.75,
            "fall": 1.15,
        }[self.environment.season]

        contamination_multiplier = 1 + self.environment.contamination * 0.55
        dryness_multiplier = 1 + self.environment.climate_dryness * 0.45

        risk_multiplier = 1.0

        if target_agent.age < 10:
            risk_multiplier += 0.15
        elif target_agent.age > 65:
            risk_multiplier += 0.25

        if target_agent.chronic_condition:
            risk_multiplier += 0.20

        protection_multiplier = 1.0
        protection_multiplier -= target_agent.immunity * 0.35

        if target_agent.mask_usage:
            protection_multiplier -= 0.25

        if target_agent.vaccinated:
            if disease == HealthState.INFECTED_FLU:
                protection_multiplier -= 0.30
            elif disease == HealthState.INFECTED_COVID:
                protection_multiplier -= 0.35
            else:
                protection_multiplier -= 0.05

        probability = (
            base_probability
            * season_multiplier
            * contamination_multiplier
            * dryness_multiplier
            * risk_multiplier
            * protection_multiplier
        )

        return max(0.0, min(probability, 0.75))

    def count_state(self, state):
        return sum(1 for agent in self.agents if agent.health_state == state)

    def step(self):
        self.environment.update(self.day)
        self.datacollector.collect(self)
        self.agents.shuffle_do("step")
        self.day += 1