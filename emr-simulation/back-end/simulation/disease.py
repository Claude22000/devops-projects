from enum import Enum


class HealthState(Enum):
    SUSCEPTIBLE = "S"
    INFECTED_FLU = "FLU"
    INFECTED_COVID = "COVID"
    INFECTED_COLD = "COLD"
    RECOVERED = "R"


RECOVERY_DAYS = {
    HealthState.INFECTED_COLD: 5,
    HealthState.INFECTED_FLU: 8,
    HealthState.INFECTED_COVID: 12,
}


BASE_TRANSMISSION = {
    HealthState.INFECTED_COLD: 0.06,
    HealthState.INFECTED_FLU: 0.09,
    HealthState.INFECTED_COVID: 0.12,
}