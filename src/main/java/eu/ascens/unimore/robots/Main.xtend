package eu.ascens.unimore.robots

import com.google.common.collect.Sets
import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.disperse.DisperseBehaviourImpl
import eu.ascens.unimore.robots.evaluation.Evaluation
import eu.ascens.unimore.robots.evaluation.ParameterValue
import eu.ascens.unimore.robots.levy.LevyBehaviourImpl
import eu.ascens.unimore.robots.mason.InitialisationParameters
import eu.ascens.unimore.robots.mason.InitialisationParametersBuilder
import eu.ascens.unimore.robots.mason.datatypes.Stats
import fj.data.List
import java.io.File
import java.io.FileWriter

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

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
			//SimulationConstants.DEFAULT_MAZE,
			"maze1",
			SimulationConstants.SEED,
			SimulationConstants.NB_BOTS,
			SimulationConstants.NB_VICTIMS,
			SimulationConstants.MIN_BOTS_PER_VICTIM,
			SimulationConstants.MAX_BOTS_PER_VICTIM,
			SimulationConstants.DEFAULT_BEHAVIOUR
			//[|new LevyBehaviourImpl]
		)
		val c = new AscensRobotsImpl(parameters).newComponent
		c.control.startGUI
	}

	static def runEvaluations() {
		val parametersSets = Sets.cartesianProduct(parameters.map[values.toSet].toList)
		val size = parametersSets.size
		parametersSets.forEach[ps, run|
			loop(List.iterableList(ps), run, size)
		]
	}

	static def loop(List<ParameterValue> parameters, int run, int size) {
		
		val parametersBuilder = new InitialisationParametersBuilder() => [
			radioRange(SimulationConstants.RADIO_RANGE)
			wallRange(SimulationConstants.WALL_RANGE)
			victimRange(SimulationConstants.VICTIM_RANGE)
			proximityBotRange(SimulationConstants.PROXIMITY_RANGE)
			speed(SimulationConstants.SPEED)
			nbProximityWallSensors(SimulationConstants.NB_WALL_SENSORS)
			seed(SimulationConstants.SEED)
			// default values
			rbRange(SimulationConstants.RB_RANGE)
			minBotsPerVictim(SimulationConstants.MIN_BOTS_PER_VICTIM)
			maxBotsPerVictim(SimulationConstants.MAX_BOTS_PER_VICTIM)
		]
			
		for (p: parameters) {
			p.set(parametersBuilder)
		}
		
		val file = new File("evaluation/run_"+parameters.map[name+"."+valueName].join("_")+".csv")
		println('''
			Run «run»/«size» to «file.toString»
			«FOR p: parameters»
				«p.name»: «p.valueName»
			«ENDFOR»
		''')
		
		val initParam = parametersBuilder.build
		
		if (!initParam.verifyParameters) {
			println("Invalid configuration, skipping.")
			return
		}
		
		val start = System.currentTimeMillis
		
		val c = new AscensRobotsImpl(initParam).newComponent
		
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
		println("Finished Run "+run+" ("+(end-start)+" ms)\n\n")
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
				if (parameters.nbVictims > 6) return false
			}
		}
		return true
	}
	
	static val metrics = List.list(
		Evaluation.metric("discovered", [Stats s|s.nbDiscovered]),
		Evaluation.metric("secured", [Stats s|s.nbSecured]),
		Evaluation.metric("explored", [Stats s|s.percentExplored])
	)
	
	static val parameters = List.list(
		Evaluation.parameter(
			"algorithm", [InitialisationParametersBuilder b, () => Behaviour algo|b.newBehaviour(algo)],
			// need to explicit type, because of https://bugs.eclipse.org/bugs/show_bug.cgi?id=429138 ?
			List.<Pair<String,() => Behaviour>>list(
				"amas" -> [|new BehaviourImpl]//,
				//"disperse" -> [|new DisperseBehaviourImpl],
				//"levy" -> [|new LevyBehaviourImpl]
			)
		),
		Evaluation.parameter2(
			"nbBots", [InitialisationParametersBuilder b, int nbBots|b.nbBots(nbBots)],
			//List.list(10, 20, 30, 50, 60, 80, 100, 150, 200, 250, 300, 500)
			List.list(/*10, 60, 90, */250, 500)
		),
		Evaluation.parameter2(
			"nbVictims", [InitialisationParametersBuilder b, int nbVictims|b.nbVictims(nbVictims)],
			//List.list(1, 3, 6, 8, 15, 20, 35, 50)
			List.list(/*8, */35)
		),
		Evaluation.parameter2(
			"map", [InitialisationParametersBuilder b, String maze|b.map(maze)],
			List.list("maze1","maze2","maze3","maze5")
		)
//		Evaluation.parameter(
//			"minMaxBotperVictim", [InitialisationParametersBuilder b, Pair<Integer,Integer> p|b.minBotsPerVictim(p.key).maxBotsPerVictim(p.value)],
//			List.list("1-2" -> (1 -> 2), "2-4" -> (2 -> 4), "3-6" -> (3 -> 6))
//		),
//		Evaluation.parameter2(
//			"rbRange", [InitialisationParametersBuilder b, double rbRange|b.rbRange(rbRange)],
//			List.list(3.0, 4.0, 5.0, 7.0, 10.0, 15.0, 20.0, 25.0)
//		)
	)
}
