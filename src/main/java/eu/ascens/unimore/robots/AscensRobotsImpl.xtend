package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.mason.AscensMasonImpl
import eu.ascens.unimore.robots.mason.InitialisationParameters
import eu.ascens.unimore.robots.mason.NoStartingAreaAvailable
import fr.irit.smac.may.lib.components.collections.ConcurrentQueueImpl

class AscensRobotsImpl extends AscensRobots {
	
	val InitialisationParameters parameters
	
	new(InitialisationParameters parameters) {
		this.parameters = parameters
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
		new RobotAgentImpl(parameters)
	}
}

class RobotAgentImpl extends AscensRobots.RobotAgent {
	
	val InitialisationParameters parameters
	
	new(InitialisationParameters parameters) {
		this.parameters = parameters
	}
	
	override protected make_beh() {
		parameters.newBehaviour.apply
	}
	
	override protected make_mbox() {
		new ConcurrentQueueImpl
	}
}