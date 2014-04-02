package eu.ascens.unimore.robots

import com.google.common.collect.Sets
import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.disperse.DisperseBehaviourImpl
import eu.ascens.unimore.robots.evaluation.Evaluation
import eu.ascens.unimore.robots.evaluation.ParameterValue
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
			SimulationConstants.RADIO_RANGE,
			SimulationConstants.WALL_RANGE,
			SimulationConstants.VICTIM_RANGE,
			SimulationConstants.PROXIMITY_RANGE,
			SimulationConstants.SPEED,
			SimulationConstants.RB_RANGE,
			SimulationConstants.NB_WALL_SENSORS,
			//SimulationConstants.DEFAULT_MAZE,
			"maze5",
			SimulationConstants.SEED,
			//SimulationConstants.NB_BOTS,
			200,
			//SimulationConstants.NB_VICTIMS,
			35,
			SimulationConstants.MIN_BOTS_PER_VICTIM,
			SimulationConstants.MAX_BOTS_PER_VICTIM,
			SimulationConstants.DEFAULT_BEHAVIOUR
			//[|new DisperseBehaviourImpl]
			//[|new LevyBehaviourImpl]
		)
		val c = new AscensRobotsImpl(parameters).newComponent
		c.control.startGUI
	}
}

class Eval {

	def static void main(String[] args) {
		val start = System.currentTimeMillis
		
		val size = parametersConfigurations.size
		
		parametersConfigurations.forEach[ps, run|
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

	static def loop(List<ParameterValue> parameters, File file) {
		
		val start = System.currentTimeMillis
		
		val c = new AscensRobotsImpl(parameters.buildParameters).newComponent
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
		} while (!stats.shouldStop)
		
		c.control.shutdown
		fw.close
		
		val end = System.currentTimeMillis
		println("Finished Run: "+prettyPrint(end-start)+"\n\n")
		
	}
	
	static def shouldStop(Stats s) {
		(s.percentExplored >= 100 && s.allSecured) || s.step > 10000
	}
	
	static def verifyParameters(InitialisationParameters parameters) {
		switch parameters.map {
			case "maze1": {
				if (parameters.nbBots > 60) return false
				if (parameters.nbVictims > 8) return false
			}
			case "maze2": {
				if (parameters.nbBots > 272) return false
				if (parameters.nbVictims > 8) return false
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
//		switch parameters.newBehaviour.apply {
//			LevyBehaviourImpl: {
//				// Levy do not use rb: this allows for only one run
//				if (parameters.rbRange > 3.0) return false
//			}
//			DisperseBehaviourImpl: {
//				// disperse do not use rb farther than VICTIM_RANGE
//				if (parameters.rbRange > SimulationConstants.VICTIM_RANGE) return false
//			}
//		}
		return true
	}
	
	static val metrics = List.list(
		Evaluation.metric("discovered", [Stats s|s.nbDiscovered]),
		Evaluation.metric("secured", [Stats s|s.nbSecured]),
		Evaluation.metric("explored", [Stats s|s.percentExplored])
	)
	
	static val parameters = List.list(
		Evaluation.parameter2(
			"map", [InitialisationParametersBuilder b, String maze|b.map(maze)],
			List.list("maze1","maze2","maze5") //"maze1","maze2","maze3","maze5"
		),
		Evaluation.parameter(
			"algorithm", [InitialisationParametersBuilder b, () => Behaviour algo|b.newBehaviour(algo)],
			// need to explicit type, because of https://bugs.eclipse.org/bugs/show_bug.cgi?id=429138
			// fixed in 2.6
			List.<Pair<String,() => Behaviour>>list(
				"amas" -> [|new BehaviourImpl],
				"disperse" -> [|new DisperseBehaviourImpl]
				//"levy" -> [|new LevyBehaviourImpl]
			)
		),
		Evaluation.parameter2(
			"nbBots", [InitialisationParametersBuilder b, int nbBots|b.nbBots(nbBots)],
			List.list(60, 90, 150, 250, 500)
		),
		Evaluation.parameter2(
			"nbVictims", [InitialisationParametersBuilder b, int nbVictims|b.nbVictims(nbVictims)],
			List.list(8, 16) // 8, 10, 16, 25, 35
		),
		Evaluation.parameter2(
			"rbRange", [InitialisationParametersBuilder b, double rbRange|b.rbRange(rbRange)],
			List.list(3.0, 20.0) //3.0, 5.0, 10.0, 20.0
		)
	)
	
	static def buildParameters(Iterable<ParameterValue> ps) {
		val b = new InitialisationParametersBuilder() => [
			radioRange(SimulationConstants.RADIO_RANGE)
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
	
	static val parametersConfigurations =
		List.iterableList(Sets.cartesianProduct(parameters.map[values.toSet].toList))
		.bind[
			if (it.buildParameters.verifyParameters) {
				List.single(List.iterableList(it))
			}
			else {
				List.nil
			}
		]
	
	static def choiceFor(int index, String noun) {
		"{index,choice,0#|1#1 noun |1<{index,number,integer} nouns }"
			.replace("index", String.valueOf(index))
			.replace("noun", noun);
	}
	
	static def prettyPrint(long ms) {
		val d = DatatypeFactory.newInstance().newDuration(ms)
		val fmt = choiceFor(0, "hour")
					+ choiceFor(1, "minute")
					+ choiceFor(2, "second");
		MessageFormat.format(fmt, d.hours, d.minutes, d.seconds).trim();
	}
		
}
