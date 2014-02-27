package eu.ascens.unimore.robots.disperse

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.RequirementsConstants
import eu.ascens.unimore.robots.SimulationConstants
import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import fj.Equal
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.robots.geometry.ObstacleAvoidance.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

class DisperseBehaviourImpl extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		this
	}
	
	static val crowdOrd = Ord.doubleOrd
	static val crowdEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= 0.1
	]]
	
	@StepCached
	private def void step() {
		val victimsOfInterest =	consideredVictims
		
		if (victimsOfInterest.empty) {
			val to = requires.see.sensorReadings
				.map[dir]
				.chooseBetweenEquivalentDirections
			goTo(to)
		} else {
			val v = victimsOfInterest.minimum(
				Ord.doubleOrd.comap[SeenVictim v|v.direction.lengthSq]
			)
			if (v.direction.lengthSq > 0.01) {
				requires.move.setNextMove(v.direction)
			}
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
		direction.dot(lastMove)
	}
	
	// the bigger, the closer to the farthest from the crowd
	private def distanceToCrowd(Double2D direction) {
		direction.dot(escapeCrowdVector)
	}
	
	@Cached
	def Double2D escapeCrowdVector() {
		requires.see.RBVisibleRobots
		.map[coord]
		.filter[b|
			b.length < SimulationConstants.VICTIM_RANGE
			&& !requires.see.visibleVictims.exists[
				dir.distanceSq(b) < RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			]
		].computeCrowdVector
	}
	
	var lastMove = new Double2D(0,0)
	def goTo(Double2D to) {
		val l = to.length
		if (l > 0.01) {			
			// TODO: smooth things using prevDirs? like not moving if it's useless
			val move = to.computeDirectionWithAvoidance(requires.see.sensorReadings).dir.resize(l)
			lastMove = to
			requires.move.setNextMove(move)
		}
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
	
	
	
	
	override choice() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override move() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override visibleBots() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override explorables() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override victimsFromMe() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override areasOnlyFromMe() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override explorablesFromOthers() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
}