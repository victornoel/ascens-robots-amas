package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.mason.AscensMasonImpl
import eu.ascens.unimore.robots.mason.NoStartingAreaAvailable
import fr.irit.smac.may.lib.components.collections.ConcurrentQueueImpl
import eu.ascens.unimore.robots.mason.InitialisationParemeters

class AscensRobotsImpl extends AscensRobots {
	
	val InitialisationParemeters parameters
	
	new(InitialisationParemeters parameters) {
		this.parameters = parameters
	}
	
	def static void main(String[] args) {
		val parameters = new InitialisationParemeters(
			Constants.RADIO_RANGE,
			Constants.VISION_RANGE,
			Constants.SPEED,
			Constants.RB_RANGE,
			Constants.DEFAULT_MAZE,
			Constants.SEED,
			Constants.NB_BOTS
		)
		new AscensRobotsImpl(parameters).newComponent
	}
	
	override protected make_populate() {[|
		var nbCreated = 0
		try {
			for(i: 1..this.parameters.nbBots) {
				newRobotAgent()
				nbCreated = i
			}
		} catch (NoStartingAreaAvailable e) {
			println("no more starting area available, created "+nbCreated+" robots.")
		}
	]}
	
	override protected make_env() {
		new AscensMasonImpl(parameters)
	}
	
	override protected make_RobotAgent() {
		new RobotAgentImpl
	}
}

class RobotAgentImpl extends AscensRobots.RobotAgent {
	
	override protected make_beh() {
		new BehaviourImpl
	}
	
	override protected make_mbox() {
		new ConcurrentQueueImpl
	}
}