package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.mason.AscensMasonImpl
import fr.irit.smac.may.lib.components.collections.ConcurrentQueueImpl

class AscensRobotsImpl extends AscensRobots {
	
	def static void main(String[] args) {
		new AscensRobotsImpl().newComponent
	}
	
	override protected make_populate() {[|
		for(i: 1..100) {
			newRobotAgent()
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
	
	override protected make_mboxRB() {
		new ConcurrentQueueImpl
	}
}