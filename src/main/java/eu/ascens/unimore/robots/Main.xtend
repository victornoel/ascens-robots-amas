package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.mason.InitialisationParameters

class Main {
	
	def static void main(String[] args) {
		val parameters = new InitialisationParameters(
			Constants.RADIO_RANGE,
			Constants.WALL_RANGE,
			Constants.VICTIM_RANGE,
			Constants.PROXIMITY_RANGE,
			Constants.SPEED,
			Constants.RB_RANGE,
			Constants.DEFAULT_MAZE,
			Constants.SEED,
			Constants.NB_BOTS,
			[|new BehaviourImpl]
		)
		new AscensRobotsImpl(parameters).newComponent
	}
	
}