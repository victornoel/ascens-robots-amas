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

import static extension eu.ascens.unimore.robots.common.GeometryExtensions.*
import static extension eu.ascens.unimore.robots.common.ObstacleAvoidance.*
import static extension eu.ascens.unimore.robots.common.VictimVision.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

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
			.maximums(crowdEq.comap(P2.__2), crowdOrd.comap(P2.__2))
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
//		.filter[b|
//			// -0.5 because if not it could escape a stopped bot
//			b.length < SimulationConstants.VICTIM_RANGE-0.5
//			&& !requires.see.visibleVictims.exists[
//				dir.distanceSq(b) <= RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
//			]
//		]
		.computeCrowdVector
	}
	
	var lastMove = new Double2D(0,0)
	def goTo(Double2D to) {
		val l = to.length
		if (l > 0.01) {
			val move = to.computeDirectionWithAvoidance(makeVision(requires.see.sensorReadings)).dir.resize(l)
			lastMove = to
			requires.move.setNextMove(move)
		}
	}
	
	@Cached
	private def List<SeenVictim> seenVictims() {
		requires.see.visibleVictims.map[
			toSeenVictim(requires.see.RBVisibleRobots,requires.see.visibleVictims)
		]
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
	
	@Cached
	private def List<SeenVictim> consideredVictims() {
		seenVictims.filter[inNeed]
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