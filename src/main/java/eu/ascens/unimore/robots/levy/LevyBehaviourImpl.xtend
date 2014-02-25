package eu.ascens.unimore.robots.levy

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.RequirementsConstants
import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import fj.Ord
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class LevyBehaviourImpl extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		this
	}
	
	override choice() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override move() {
		currentDir
	}
	
	override visibleBots() {
		requires.see.RBVisibleRobots.map[coord]
	}
	
	override explorables() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override victimsFromMe() {
		consideredVictims
	}
	
	override areasOnlyFromMe() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override explorablesFromOthers() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	private var Double2D currentDir
	private var double alpha
	private var double accumulator
		
	@StepCached
	private def void step() {
		
		val victimsOfInterest =	consideredVictims
		
		if (victimsOfInterest.empty) {
			if (currentDir == null || shouldChange) {
				currentDir = randomDirection()
				alpha = requires.random.pull.nextDouble
				accumulator = 0
			}
			if (!bump) {
				requires.move.setNextMove(currentDir)
				accumulator = accumulator + alpha
			}
		} else {
			val v = victimsOfInterest.minimum(
				Ord.intOrd.comap[SeenVictim v|v.howMuch]
				|| Ord.doubleOrd.comap[SeenVictim v|v.direction.lengthSq]
			)
			currentDir = v.direction
			if (v.direction.lengthSq > 0.01) {
				requires.move.setNextMove(currentDir)
			}
		}
	}
	
	def bump() {
		requires.see.sensorReadings.exists[
			((hasWall && dir.lengthSq < 1)
			|| (hasBot && dir.lengthSq < 1))
			&& currentDir.between(cone)
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
		requires.see.visibleVictims
		.map[v|
			val myDistToVictSq = v.dir.lengthSq
			val ImNext = new Double2D(0,0).isConsideredNextTo(myDistToVictSq)
			new SeenVictim(v.dir,
				requires.see.RBVisibleRobots.count[
					coord.isConsideredNextTo(coord.distanceSq(v.dir))
				] + (if (ImNext) 1 else 0),
				v.nbBotsNeeded,
				ImNext
			)
		]
	}
	
	@Cached
	private def List<SeenVictim> consideredVictims() {
		seenVictims.filter[
			if (imNext) howMuch <= nbBotsNeeded
			else howMuch < nbBotsNeeded
		]
	}
	
	private def isConsideredNextTo(Double2D who, double hisDistToVictSq) {
		// bot is close enough to victim
		hisDistToVictSq <= RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			// but not closer to another victim
			&& who.isCloserTo(hisDistToVictSq)
	}
	
	private def isCloserTo(Double2D who, double distToWhatSq) {
		!requires.see.visibleVictims.exists[ov|
			who.distanceSq(ov.dir) < distToWhatSq
		]
	}
	
}