package eu.ascens.unimore.robots.mason

import eu.ascens.unimore.robots.RequirementsConstants
import sim.util.Double2D

class Victim {
	
	@Property val Double2D position
	@Property val int nbBotNeeded
	
	val AscensSimState state
	
	new(AscensSimState state) {
		val diff = state.parameters.maxBotsPerVictim-state.parameters.minBotsPerVictim
		this._nbBotNeeded = state.parameters.minBotsPerVictim
								+ if (diff != 0) state.random.nextInt(diff) else 0
		this._position = state.add(this)
		this.state = state
	}
	
//	var wasSecured = false
//	var howLongNot = 0
	def isSecured() {
		val agentsHere = state.agents.getNeighborsExactlyWithinDistance(position, RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE)
		if (agentsHere != null) {
			val nbBots = agentsHere.filter(MasonRobot).size
			if (nbBots >= nbBotNeeded) {
//				wasSecured = true
				return true
			}
		}
		// to avoid glitches in stats
		// TODO better would be to have bots go around other bots and victims...
//		if (wasSecured && howLongNot < 5) {
//			howLongNot = howLongNot + 1
//			return true
//		} else {
//			wasSecured = false
//			howLongNot = 0
//			return false
//		}
		return false
	}
	
	var discovered = false
	def boolean isDiscovered() {
		if (!discovered) {
			val iPos = state.agents.discretize(position)
			discovered = state.isExplored(iPos.x,iPos.y)
		}
		discovered
	}
}
