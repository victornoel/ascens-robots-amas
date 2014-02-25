package eu.ascens.unimore.robots.mason

import sim.util.Double2D
import eu.ascens.unimore.robots.RequirementsConstants

class Victim {
	
	@Property val Double2D position
	@Property val int nbBotNeeded
	
	var discovered = false
	val AscensSimState state
	
	new(AscensSimState state) {
		this._nbBotNeeded = state.parameters.minBotsPerVictim + state.random.nextInt(state.parameters.maxBotsPerVictim-state.parameters.minBotsPerVictim)
		this._position = state.add(this)
		this.state = state
	}
	
	def isSecured() {
		val agentsHere = state.agents.getNeighborsExactlyWithinDistance(position, RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE)
		if (agentsHere != null) {
			val nbBots = agentsHere.filter(MasonRobot).size
			if (nbBots > 0) {
				discovered = true
			}
			if (nbBots >= nbBotNeeded) {
				return true
			}
		}
		return false
	}
	
	def isDiscovered() {
		discovered
	}
}