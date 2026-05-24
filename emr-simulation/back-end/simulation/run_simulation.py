from simulation.model import RespiratoryDiseaseModel


def main():
    model = RespiratoryDiseaseModel(
        population=800,
        width=50,
        height=50,
        initial_infected=15,
        city="Tijuana",
    )

    for _ in range(365):
        model.step()

    data = model.datacollector.get_model_vars_dataframe()

    print(data.tail())

    data[["Flu", "Covid", "Cold", "Recovered"]].plot()


if __name__ == "__main__":
    main()