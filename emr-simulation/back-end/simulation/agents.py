import random
from mesa import Agent
from simulation.disease import HealthState, RECOVERY_DAYS


class PersonAgent(Agent):
    def __init__(self, model, age):
        super().__init__(model)

        self.age = age
        self.health_state = HealthState.SUSCEPTIBLE
        self.days_infected = 0

        self.immunity = random.uniform(0.2, 0.9)
        self.mask_usage = random.random() < 0.25
        self.vaccinated = random.random() < 0.45
        self.mobility = random.uniform(0.3, 1.0)
        self.chronic_condition = random.random() < self.chronic_risk()

    def chronic_risk(self):
        if self.age < 30:
            return 0.05
        if self.age < 60:
            return 0.15
        return 0.35

    def step(self):
        self.move()
        self.try_infect_neighbors()
        self.update_infection()

    def move(self):
        if random.random() > self.mobility:
            return

        possible_steps = self.model.grid.get_neighborhood(
            self.pos,
            moore=True,
            include_center=False
        )

        self.model.grid.move_agent(self, random.choice(possible_steps))

    def try_infect_neighbors(self):
        if self.health_state not in [
            HealthState.INFECTED_FLU,
            HealthState.INFECTED_COVID,
            HealthState.INFECTED_COLD,
        ]:
            return

        neighborhood = self.model.grid.get_neighborhood(
            self.pos,
            moore=True,
            include_center=True
        )

        neighbors = self.model.grid.get_cell_list_contents(neighborhood)

        for neighbor in neighbors:
            if not isinstance(neighbor, PersonAgent):
                continue

            if neighbor.health_state != HealthState.SUSCEPTIBLE:
                continue

            probability = self.model.get_transmission_probability(
                disease=self.health_state,
                infected_agent=self,
                target_agent=neighbor
            )

            if random.random() < probability:
                neighbor.health_state = self.health_state
                neighbor.days_infected = 0

    def update_infection(self):
        if self.health_state in [HealthState.SUSCEPTIBLE, HealthState.RECOVERED]:
            return

        self.days_infected += 1

        if self.days_infected >= RECOVERY_DAYS[self.health_state]:
            self.health_state = HealthState.RECOVERED
            self.days_infected = 0