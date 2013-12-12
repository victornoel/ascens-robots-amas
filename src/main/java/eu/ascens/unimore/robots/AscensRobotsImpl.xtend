package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.mason.AscensMasonImpl
import eu.ascens.unimore.robots.mason.NoStartingAreaAvailable
import fr.irit.smac.may.lib.components.collections.ConcurrentQueueImpl

class AscensRobotsImpl extends AscensRobots {
	
	def static void main(String[] args) {
		new AscensRobotsImpl().newComponent
	}
	
	override protected make_populate() {[|
		var nbCreated = 0
		try {
			for(i: 1..Constants.NB_BOTS) {
				newRobotAgent()
				nbCreated = i
			}
		} catch (NoStartingAreaAvailable e) {
			println("no more starting area available, created "+nbCreated+" robots.")
		}
	]}
	
	override protected make_env() {
		new AscensMasonImpl
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