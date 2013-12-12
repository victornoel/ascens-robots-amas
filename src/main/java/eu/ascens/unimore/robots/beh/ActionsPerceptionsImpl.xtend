package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IActionsExtra
import eu.ascens.unimore.robots.beh.interfaces.IPerceptionsExtra
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.Ord
import fj.data.List
import fj.data.Stream
import fj.data.Zipper
import org.eclipse.xtext.xbase.lib.Pair
import org.slf4j.LoggerFactory
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

class ActionsPerceptionsImpl extends ActionsPerceptions implements IActionsExtra, IPerceptionsExtra {

	val logger = LoggerFactory.getLogger("agent")

	override protected make_preStep() {
		[|preStep]
	}
	
	@Step
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
	
	override broadcastExplorables(List<Explorable> explorables) {
		requires.rbPublish.push(new ExplorableMessage(explorables))
	}
	
	override previousDirection() {
		lastMove
	}
	
	override goingBack(Double2D dir) {
		dir.dot(previousDirection) < 0
	}
	
	override goTo(Double2D to) {
//		if (to.lengthSq > 0) {
			
			// TODO maybe difference speed and directions? smooth only on speed!
			val realTo = lastMove*0.6+to.resize(Math.min(to.length, Constants.SPEED))*0.4
			
			// TODO: smooth things using prevDirs? like not moving if it's useless
			val move = realTo.computeDirectionWithAvoidance.dir.resize(realTo.length)
			lastMove = realTo
			
			logger.info("going to {} targetting {}.", move, realTo)
			requires.move.setNextMove(move)
//		}
	}
	
	// taken from http://link.springer.com/chapter/10.1007%2F978-3-642-22907-7_7
	private def computeDirectionWithAvoidance(Double2D to) {
		
		val sensorsReadingsWithLengthSq = sensorReadings.map[it -> it.dir.lengthSq]
		// this is the best I can get
		val maxSq = sensorsReadingsWithLengthSq.map[value].maximum(Ord.doubleOrd)-0.1
		
		val vision = Zipper.fromStream(Stream.iterableStream(sensorsReadingsWithLengthSq)).some
		
		val desiredDirection = vision.find[d|to.between(d.key.cone)].some
		
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
	
	private def chooseBest(Zipper<Pair<SensorReading, Double>> z, double maxSq, boolean inverse) {
		val prev = z.cyclePrevious(inverse)
		val prevprev = prev.cyclePrevious(inverse)
		val next = z.cycleNext(inverse)
		val nextnext = next.cycleNext(inverse)
		if (prev.focus.value < Constants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED || prevprev.focus.value < Constants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED) {
			if (next.focus.value >= maxSq) {
				if (nextnext.focus.value >= maxSq) {
					return nextnext.focus.key
				}
				return next.focus.key
			}
		}
		if (next.focus.value < Constants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED || nextnext.focus.value < Constants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED) {
			if (prev.focus.value >= maxSq) {
				if (prevprev.focus.value >= maxSq) {
					return prevprev.focus.key
				}
				return prev.focus.key
			}
		}
		return z.focus.key
	}
	
	def <A> cycleNext(Zipper<A> z, boolean inverse) {
		if (inverse) z.cyclePrevious
		else z.cycleNext
	}
	
	def <A> cyclePrevious(Zipper<A> z, boolean inverse) {
		if (inverse) z.cycleNext
		else z.cyclePrevious
	}
	
	override myId() {
		requires.id.pull
	}
	
	@StepCached
	override visibleFreeAreas() {
		sensorReadings
			.filter[!hasWall]
	}
	
	@StepCached
	override visibleWalls() {
		sensorReadings
			.filter[hasWall]
	}

	@StepCached
	private def sensorReadings() {
		requires.see.sensorReadings
			=> [logger.info("sensorReadings: {}", it)]
	}
	
	@StepCached
	override visibleRobots() {
		requires.see.RBVisibleRobots
			=> [logger.info("visibleRobots: {}", it)]
	}
	
	@StepCached
	override visibleVictims() {
		requires.see.visibleVictims
			=> [logger.info("visibleVictims: {}", it)]
	}

	@StepCached
	override visionConesCoveredByVisibleRobots() {
		visibleRobots.map[id -> coord.computeConeCoveredByBot(Constants.VISION_RANGE_SQUARED)]
	}
	
	@StepCached
	override escapeCrowdVector() {
		visibleRobots.map[coord].computeCrowdVector
	}
}
