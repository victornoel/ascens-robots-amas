package eu.ascens.unimore.robots

import com.google.common.collect.Sets
import eu.ascens.unimore.robots.evaluation.Evaluation
import eu.ascens.unimore.robots.evaluation.ParameterValue
import eu.ascens.unimore.robots.levy.LevyBehaviourImpl
import eu.ascens.unimore.robots.mason.InitialisationParameters
import eu.ascens.unimore.robots.mason.InitialisationParametersBuilder
import eu.ascens.unimore.robots.mason.datatypes.Stats
import fj.data.List
import java.io.File
import java.io.FileWriter
import java.text.MessageFormat
import javax.xml.datatype.DatatypeFactory

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

class GUI {
	def static void main(String[] args) {
		val parameters = new InitialisationParameters(
			//SimulationConstants.RADIO_RANGE,
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
}

class Eval {

	def static void main(String[] args) {
		val start = System.currentTimeMillis
		
		val configurations = List.iterableList(Sets.cartesianProduct(parameters.map[values.toSet].toList))
								.filter[buildParameters.verifyParameters]
								.map[List.iterableList(it)]
		
		val size = configurations.size
		
		configurations.forEach[ps, run|
			val file = new File("evaluation/run_"+ps.map[name+"."+valueName].join("_")+".csv")
			println('''
				Run «run+1»/«size» to «file.toString»
				«FOR p: ps»
					«p.name»: «p.valueName»
				«ENDFOR»
			''')
			loop(ps, file)
		]
		
		val end = System.currentTimeMillis
		
		println("Overall time: "+prettyPrint(end-start))
	}

	private static def loop(List<ParameterValue> parameters, File file) {
		
		val start = System.currentTimeMillis
		val initParameters = parameters.buildParameters
		val c = new AscensRobotsImpl(initParameters).newComponent
		val fw = new FileWriter(file)
		
		fw.write("step"+ (metrics.map[name]+parameters.map[name]).join(";",";","",[it])+ "\n")
		
		val parametersValueNames = parameters.map[valueName]
		
		c.control.setup
		var Stats stats
		do {
			c.control.step
			stats = c.control.currentStats
			val s = stats
			fw.write(s.step + (metrics.map[get(s)] + parametersValueNames).join(";",";","",[it])+ "\n")
		} while (!stats.shouldStop(initParameters))
		
		c.control.shutdown
		fw.close
		
		val end = System.currentTimeMillis
		println("Finished Run: "+prettyPrint(end-start)+"\n\n")
		
	}
	
	private static def maxSteps(InitialisationParameters parameters) {
		switch parameters.map {
			case "maze1": 10000
			case "maze2": 10000
			case "maze3": 15000
			case "maze5": 10000
		}
	}
	
	private static def shouldStop(Stats s, InitialisationParameters parameters) {
		(s.percentExplored >= 95 && s.allSecured) || s.step > maxSteps(parameters)
	}
	
	private static def verifyParameters(InitialisationParameters parameters) {
		switch parameters.map {
			case "maze1": {
				if (parameters.nbBots > 60) return false
				if (parameters.nbVictims > 16) return false
			}
			case "maze2": {
				if (parameters.nbBots > 272) return false
				if (parameters.nbVictims > 16) return false
			}
			case "maze3": {
				if (parameters.nbBots > 564) return false
				if (parameters.nbVictims > 35) return false
			}
			case "maze5": {
				if (parameters.nbBots > 90) return false
				if (parameters.nbVictims > 16) return false
			}
		}
		switch parameters.newBehaviour.apply {
			LevyBehaviourImpl: {
				// Levy do not use rb: this allows for only one run
				if (parameters.rbRange > 3.0) return false
			}
		}
		return true
	}
	
	private static val metrics = List.list(
		Evaluation.metric("discovered", [Stats s|s.nbDiscovered]),
		Evaluation.metric("secured", [Stats s|s.nbSecured]),
		Evaluation.metric("explored", [Stats s|s.percentExplored])
	)
	
	private static val parameters = List.list(
		Evaluation.parameter2(
			"map", [InitialisationParametersBuilder b, String maze|b.map(maze)],
			List.list("maze1","maze2","maze3","maze5") //"maze1","maze2","maze3","maze5"
		),
		Evaluation.parameter(
			"algorithm", [InitialisationParametersBuilder b, () => Behaviour algo|b.newBehaviour(algo)],
			// need to explicit type, because of https://bugs.eclipse.org/bugs/show_bug.cgi?id=429138
			// fixed in 2.6
			List.<Pair<String,() => Behaviour>>list(
				"amasEV" -> SimulationConstants.BEHAVIOURS.get(0),
				"amasE" -> SimulationConstants.BEHAVIOURS.get(1),
				"disperse" -> SimulationConstants.BEHAVIOURS.get(2),
				"levy" -> SimulationConstants.BEHAVIOURS.get(3)
			)
		),
		Evaluation.parameter2(
			"nbBots", [InitialisationParametersBuilder b, int nbBots|b.nbBots(nbBots)],
			List.list(60, 90, 150, 250, 500)
		),
		Evaluation.parameter2(
			"nbVictims", [InitialisationParametersBuilder b, int nbVictims|b.nbVictims(nbVictims)],
			List.list(8, 10, 16, 25, 35) // 8, 10, 16, 25, 35
		),
		Evaluation.parameter2(
			"rbRange", [InitialisationParametersBuilder b, double rbRange|b.rbRange(rbRange)],
			List.list(3.0, 5.0, 10.0, 20.0) //3.0, 5.0, 10.0, 20.0
		)
	)
	
	private static def buildParameters(Iterable<ParameterValue> ps) {
		val b = new InitialisationParametersBuilder() => [
			//radioRange(SimulationConstants.RADIO_RANGE)
			wallRange(SimulationConstants.WALL_RANGE)
			victimRange(SimulationConstants.VICTIM_RANGE)
			proximityBotRange(SimulationConstants.PROXIMITY_RANGE)
			speed(SimulationConstants.SPEED)
			nbProximityWallSensors(SimulationConstants.NB_WALL_SENSORS)
			seed(SimulationConstants.SEED)
			// default values
			minBotsPerVictim(SimulationConstants.MIN_BOTS_PER_VICTIM)
			maxBotsPerVictim(SimulationConstants.MAX_BOTS_PER_VICTIM)
		]
		for (p: ps) {
			p.set(b)
		}
		b.build
	}
	
	private static def choiceFor(int index, String noun) {
		"{index,choice,0#|1#1 noun |1<{index,number,integer} nouns }"
			.replace("index", String.valueOf(index))
			.replace("noun", noun);
	}
	
	private static def prettyPrint(long ms) {
		val d = DatatypeFactory.newInstance().newDuration(ms)
		val fmt = choiceFor(0, "hour")
					+ choiceFor(1, "minute")
					+ choiceFor(2, "second");
		MessageFormat.format(fmt, d.hours, d.minutes, d.seconds).trim();
	}
		
}
