package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IActionsExtra
import eu.ascens.unimore.robots.beh.interfaces.IPerceptionsExtra
import eu.ascens.unimore.xtend.macros.StepCached
import fj.Ord
import fj.data.List
import fj.data.Stream
import fj.data.Zipper
import org.eclipse.xtext.xbase.lib.Pair
import org.eclipse.xtext.xbase.lib.Pure
import org.slf4j.LoggerFactory
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

class ActionsPerceptionsImpl extends ActionsPerceptions implements IActionsExtra, IPerceptionsExtra {

	val logger = LoggerFactory.getLogger("agent")

	override protected make_preStep() {
		[|preStep]
	}
	
	@StepCached
	def preStep() {}
	
	override protected make_actions() {
		this
	}
	
	override protected make_perceptions() {
		this
	}
	
	override lastMove() {
		lastMove
	}
	
	var lastMove = new Double2D(0,0)
	
	override broadcastExplorables(List<Explorable> explorables, boolean onVictim) {
		requires.rbPublish.push(new ExplorableMessage(explorables, onVictim))
	}
	
	override previousDirection() {
		lastMove
	}
	
	override goingBack(Double2D dir) {
		dir.dot(previousDirection) < 0
	}
	
	override goTo(Double2D to) {
		// TODO: smooth things using prevDirs? like not moving if it's useless
		val move = to.computeDirectionWithAvoidance.dir.resize(to.length)
		lastMove = to
		
		logger.info("going to {} targetting {}.", move, to)
		requires.move.setNextMove(move)
	}
	
	// taken from http://link.springer.com/chapter/10.1007%2F978-3-642-22907-7_7
	private def computeDirectionWithAvoidance(Double2D to) {
		
		val sensorsReadingsWithLengthSq = sensorReadings.map[r|
//			val rs = visibleRobots.filter[coord.between(r.cone)].map[
//				new SensorReading(coord, r.cone, true) -> coord.lengthSq
//			]
//			if (rs.notEmpty) rs.minimum(Ord.doubleOrd.comap[value])
//			else
//			val vs = visibleVictims.filter[between(r.cone)].map[
//				new SensorReading(it, r.cone, true) -> it.lengthSq
//			]
//			if (vs.notEmpty) vs.minimum(Ord.doubleOrd.comap[value])
//			else 
// TODO that does'nt when we want to go there exactly!
			r -> r.dir.lengthSq
		]
		// this is the best I can get
		val maxSq = sensorsReadingsWithLengthSq.map[value].maximum(Ord.doubleOrd)-0.1
		
		val vision = Zipper.fromStream(Stream.iterableStream(sensorsReadingsWithLengthSq)).some()
		
		val desiredDirection = vision.find[d|to.between(d.key.cone)].some()
		
		var gothroughR = desiredDirection
		var gothroughL = desiredDirection
		
		do {
			if (gothroughR.focus.value >= maxSq) {
				return gothroughR.chooseBest(maxSq, true)
			} else if (gothroughL.focus.value >= maxSq) {
				return gothroughL.chooseBest(maxSq, false)
			}
			gothroughR = gothroughR.cyclePrevious
			gothroughL = gothroughL.cycleNext
		} while ((gothroughR.focus != desiredDirection.focus)
			&& (gothroughL.focus != desiredDirection.focus))
		
		return desiredDirection.focus.key
	}
	
	private def <A> chooseBest(Zipper<Pair<A, Double>> z, double maxSq, boolean inverse) {
		val prev = z.cyclePrevious(inverse)
		val prevprev = prev.cyclePrevious(inverse)
		val next = z.cycleNext(inverse)
		val nextnext = next.cycleNext(inverse)
		if (prev.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED || prevprev.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED) {
			if (next.focus.value >= maxSq) {
				if (nextnext.focus.value >= maxSq) {
					return nextnext.focus.key
				}
				return next.focus.key
			}
		}
		if (next.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED || nextnext.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED) {
			if (prev.focus.value >= maxSq) {
				if (prevprev.focus.value >= maxSq) {
					return prevprev.focus.key
				}
				return prev.focus.key
			}
		}
		return z.focus.key
	}
	
	private def <A> cycleNext(Zipper<A> z, boolean inverse) {
		if (inverse) z.cyclePrevious
		else z.cycleNext
	}
	
	private def <A> cyclePrevious(Zipper<A> z, boolean inverse) {
		if (inverse) z.cycleNext
		else z.cyclePrevious
	}
	
	override myId() {
		requires.id.pull
	}
	
	@Cached
	override visibleFreeAreas() {
		sensorReadings
			.filter[!hasWall]
	}
	
	@Cached
	override visibleWalls() {
		sensorReadings
			.filter[hasWall]
	}

	@Cached
	override sensorReadings() {
		requires.see.sensorReadings
			=> [logger.info("sensorReadings: {}", it)]
	}
	
	@Cached
	override visibleRobots() {
		requires.see.RBVisibleRobots
			=> [logger.info("visibleRobots: {}", it)]
	}
	
	@Cached
	override visibleVictims() {
		requires.see.visibleVictims
			=> [logger.info("visibleVictims: {}", it)]
	}
	
	@Cached
	override escapeCrowdVector() {
		visibleRobots
		.filter[
			message.isNone
			|| !(message.some() instanceof ExplorableMessage)
			|| !(message.some() as ExplorableMessage).onVictim
		]
		.map[coord]
		.filter[r|
			!visibleVictims.exists[v|
				r.distanceSq(v) <= CoopConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			]
		]
		.computeCrowdVector
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
}
