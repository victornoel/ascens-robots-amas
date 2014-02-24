package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.mason.InitialisationParameters

class Main {
	
	def static void main(String[] args) {
		val parameters = new InitialisationParameters(
			SimulationConstants.RADIO_RANGE,
			SimulationConstants.WALL_RANGE,
			SimulationConstants.VICTIM_RANGE,
			SimulationConstants.PROXIMITY_RANGE,
			SimulationConstants.SPEED,
			SimulationConstants.RB_RANGE,
			SimulationConstants.NB_WALL_SENSORS,
			SimulationConstants.DEFAULT_MAZE,
			SimulationConstants.SEED,
			SimulationConstants.NB_BOTS,
			SimulationConstants.NB_VICTIMS,
			SimulationConstants.MIN_BOTS_PER_VICTIM,
			SimulationConstants.MAX_BOTS_PER_VICTIM,
			SimulationConstants.DEFAULT_BEHAVIOUR
		)
		new AscensRobotsImpl(parameters).newComponent
	}
	
}