package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.levy.LevyBehaviourImpl
import eu.ascens.unimore.robots.mason.InitialisationParameters
import eu.ascens.unimore.robots.mason.datatypes.Stats
import java.io.File
import java.io.FileWriter
import java.util.List

import static extension fr.irit.smac.lib.contrib.xtend.JavaExtensions.*
import eu.ascens.unimore.robots.disperse.DisperseBehaviourImpl

class Main {

	def static void main(String[] args) {
		runEvaluations
		//gui
	}
	
	static def gui() {
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
	}

	static def runEvaluations() {
		for (a : algorithms) {
			println("Running "+a.key)
			val start = System.currentTimeMillis
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
				a.value
			)
			val c = new AscensRobotsImpl(parameters).newComponent
			c.loop(a.key)
			val end = System.currentTimeMillis
			println("Finished running "+a.key+" ("+(end-start)+" ms)")
		}
	}

	static def loop(AscensRobots.Component c, String algorithm) {
		val fws = metrics.map[
			key -> new FileWriter(new File("evaluation/"+algorithm+"-"+key+".csv"))
		].toMap
		
		fws.forEach[metric,fw|
			fw.write("step;algorithm;metric\n")
		]
		
		c.control.setup
		var Stats stats
		do {
			c.control.step
			stats = c.control.currentStats
			val s = stats
			for(mf: metrics) {
				fws.get(mf.key).write(s.step + ";" + algorithm + ";" + mf.value.apply(s)+ "\n")
			}
		} while (!stats.shouldStop)

		c.control.shutdown
		fws.forEach[metric, fw|fw.close]
	}
	
	static def shouldStop(Stats s) {
		(s.percentExplored >= 100 && s.allSecured) || s.step > 10000
	}
	
	// must specify type (see: https://bugs.eclipse.org/bugs/show_bug.cgi?id=429138)
	static val List<Pair<String, () => Behaviour>> algorithms = #[
		"amas" -> [|new BehaviourImpl],
		"disperse" -> [|new DisperseBehaviourImpl],
		"levy" -> [|new LevyBehaviourImpl]
	]
	static val metrics = #[
		"discovered" -> [Stats s|s.nbDiscovered],
		"secured" -> [Stats s|s.nbSecured],
		"explored" -> [Stats s|s.percentExplored]
	]
}
