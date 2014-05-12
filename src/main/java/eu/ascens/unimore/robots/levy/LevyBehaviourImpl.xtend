package eu.ascens.unimore.robots.levy

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.common.VictimVision.*

class LevyBehaviourImpl extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		this
	}
	
	override choice() {
		new MyChoice(currentDir)
	}
	
	override move() {
		currentDir
	}
	
	override explorables() {
		List.nil
	}
	
	override victimsFromMe() {
		consideredVictims
	}
	
	override areasOnlyFromMe() {
		List.nil
	}
	
	override explorablesFromOthers() {
		List.nil
	}
	
	private var Double2D currentDir
	private var double alpha
	private var double accumulator
	
	@StepCached
	private def void step() {
		
		val victimsOfInterest =	consideredVictims
		
		if (victimsOfInterest.empty) {
			if (currentDir == null || shouldChange) {
				currentDir = randomDirection
				alpha = requires.random.pull.nextDouble(false, true)
				accumulator = 0
			}
			requires.move.setNextMove(currentDir)
			accumulator = accumulator + alpha
		} else {
			val v = victimsOfInterest.mostInNeedVictim
			currentDir = v.direction
			if (currentDir.lengthSq > 0.01) {
				requires.move.setNextMove(currentDir)
			}
		}
	}
	
	def bump() {
		requires.see.sensorReadings.exists[
			((hasWall && lengthSq < 1)
			|| (hasBot && lengthSq < 1))
			//&& currentDir.between(cone)
			&& currentDir.dot(dir) > 0
		]
	}
	
	def shouldChange() {
		accumulator > 1
		|| bump
	}
	
	def randomDirection() {
		val nbDir = requires.see.sensorReadings.length
		requires.see.sensorReadings
			.index(requires.random.pull.nextInt(nbDir))
			.dir
	}
	
	@Cached
	private def List<SeenVictim> seenVictims() {
		requires.see.visibleVictims.map[
			toSeenVictim(requires.see.RBVisibleRobots, requires.see.visibleVictims)
		]
	}
	
	@Cached
	private def List<SeenVictim> consideredVictims() {
		seenVictims.filter[needMe]
	}
	
}

@Data class MyChoice implements Choice {
	val Double2D direction
}