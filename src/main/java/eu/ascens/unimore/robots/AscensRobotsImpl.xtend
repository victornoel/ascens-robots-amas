package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.mason.AscensMasonImpl
import eu.ascens.unimore.robots.mason.InitialisationParameters

class AscensRobotsImpl extends AscensRobots {
	
	val InitialisationParameters parameters
	
	new(InitialisationParameters parameters) {
		this.parameters = parameters
	}
	
	override protected make_env() {
		new AscensMasonImpl(this.parameters)
	}
	
	override protected make_RobotAgent() {
		new RobotAgentImpl()
	}
	
	override protected make_newRobot() {[|
		newRobotAgent()
	]}
	
}

class RobotAgentImpl extends AscensRobots.RobotAgent {
	
	override protected make_beh() {
		eco_parts.env.currentParameters.pull.newBehaviour.apply
	}
	
//	override protected make_mbox() {
//		new ConcurrentQueueImpl
//	}
}