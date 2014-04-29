package eu.ascens.unimore.robots.disperse

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.robots.common.ObstacleAvoidance.*
import static extension eu.ascens.unimore.robots.common.VictimVision.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class DisperseBehaviourImpl extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		this
	}
	
	var Choice lastChoice = [|new Double2D(0,0)]
	
	@StepCached
	private def void step() {
		val victimsOfInterest =	consideredVictims
		
		if (victimsOfInterest.empty) {
			val to = requires.see.sensorReadings
				.map[dir]
				.chooseBetweenEquivalentDirections
			goTo(to)
			lastChoice = [|to]
			requires.rbPublish.push(new DisperseMessage(false))
		} else {
			val v = victimsOfInterest.mostInNeedVictim
			if (v.direction.lengthSq > 0.001) {
				requires.move.setNextMove(v.direction)
			}
			lastChoice = [|v.direction]
			requires.rbPublish.push(new DisperseMessage(true))
		}
	}
	
	private def chooseBetweenEquivalentDirections(List<Double2D> in) {
		in
			.map[e|P.p(e,e.distanceToCrowd)]
			.maximums(doubleEqWithEpsilon(0.01).comap(P2.__2), Ord.doubleOrd.comap(P2.__2))
			.map[_1]
			.map[e|P.p(e, e.distanceToLast)]
			.maximum(Ord.doubleOrd.comap(P2.__2))
			._1
	}
	
	// the bigger the closer to the previous direction
	private def distanceToLast(Double2D direction) {
		direction.dot(lastChoice.direction)
	}
	
	// the bigger, the closer to the farthest from the crowd
	private def distanceToCrowd(Double2D direction) {
		direction.dot(escapeCrowdVector)
	}
	
	@Cached
	def Double2D escapeCrowdVector() {
		requires.see.RBVisibleRobots
		.filter[
			message.isNone
			|| !(message.some() instanceof DisperseMessage)
			|| !(message.some() as DisperseMessage).onVictim
		]
		.map[coord]
		.computeCrowdVector
	}
	
	// inspired from http://buildnewgames.com/vector-field-collision-avoidance/
	@Pure
	public def computeCrowdVector(Iterable<Double2D> bots) {
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
	def goTo(Double2D to) {
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
	private def List<SeenVictim> consideredVictims() {
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
		consideredVictims
	}
	
	override areasOnlyFromMe() {
		List.nil
	}
	
	override explorablesFromOthers() {
		List.nil
	}
}

@Data class DisperseMessage extends Message {
	val boolean onVictim
}