package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.mason.InitialisationParameters
import eu.ascens.unimore.robots.mason.datatypes.Stats
import java.io.File
import java.io.FileWriter

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
		val c = new AscensRobotsImpl(parameters).newComponent
		c.control.startGUI
		//c.loop
	}
	
	static def loop(AscensRobots.Component c) {
		
		val fw = new FileWriter(new File("/tmp/stats.csv"))
		
		c.control.setup
		var Stats stats
		fw.write("step;nbDiscovered;nbSecured;percentExplored\n")
		do {
			c.control.step
			stats = c.control.currentStats
			fw.write(stats.step+";"+stats.nbDiscovered+";"+stats.nbSecured+";"+stats.percentExplored+"\n")
		} while(stats.percentExplored < 100 || !stats.allSecured)
		
		c.control.shutdown
		
		fw.close
	}
	
}