package eu.ascens.unimore.robots.disperse

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import fj.Ord
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.robots.common.ObstacleAvoidance.*
import static extension eu.ascens.unimore.robots.common.VictimVision.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class DisperseBehaviour extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		this
	}
	
	var Choice lastChoice = [|new Double2D(0,0)]
	
	@StepCached
	protected def void step() {
		if (victimsOfInterest.empty) {
			val to = requires.see.sensorReadings
						.map[dir]
						.maximums(
							doubleEqWithEpsilon(0.01).comap[distanceToCrowd],
							Ord.doubleOrd.comap[distanceToCrowd]
						)
						.maximum(Ord.doubleOrd.comap[distanceToLast])
			goTo(to)
			lastChoice = [|to]
		} else {
			val v = victimsOfInterest.mostInNeedVictim
			if (v.direction.lengthSq > 0.001) {
				requires.move.setNextMove(v.direction)
			}
			lastChoice = [|v.direction]
		}
	}
	
	// the bigger the closer to the previous direction
	@Cached
	private def double distanceToLast(Double2D direction) {
		direction.dot(lastChoice.direction)
	}
	
	// the bigger, the closer to the farthest from the crowd
	@Cached
	private def double distanceToCrowd(Double2D direction) {
		direction.dot(escapeCrowdVector)
	}
	
	@Cached
	protected def List<RBEmitter> botsToConsider() {
		requires.see.RBVisibleRobots
	}
	
	@Cached
	private def Double2D escapeCrowdVector() {
		botsToConsider.map[coord].computeCrowdVector
	}
	
	// inspired from http://buildnewgames.com/vector-field-collision-avoidance/
	@Pure
	private def computeCrowdVector(Iterable<Double2D> bots) {
		val v = new MutableDouble2D(0,0)
		for(o: bots) {
			val lsq = o.lengthSq
			if (lsq > 0) {
				v -= o.resize(1.0/lsq)
			}
		}
		new Double2D(v)
	}
	
	var lastMove = new Double2D(0,0)
	private def goTo(Double2D to) {
		val l = to.length
		if (l > 0) {
			val av = to.computeDirectionWithAvoidance(requires.see.sensorReadings)
			if (av.isSome) {
				val move = av.some().dir.resize(l)
				lastMove = move
				requires.move.setNextMove(move)
			}
		}
	}
	
	@Cached
	private def List<SeenVictim> seenVictims() {
		requires.see.visibleVictims.map[
			toSeenVictim(requires.see.RBVisibleRobots,requires.see.visibleVictims)
		]
	}
	
	@Cached
	protected def List<SeenVictim> victimsOfInterest() {
		seenVictims.filter[needMe]
	}
	
	override choice() {
		lastChoice
	}
	
	override move() {
		lastMove
	}
	
	override explorables() {
		List.nil
	}
	
	override victimsFromMe() {
		victimsOfInterest
	}
	
	override areasOnlyFromMe() {
		List.nil
	}
	
	override explorablesFromOthers() {
		List.nil
	}
}