package eu.ascens.unimore.robots.geometry

import eu.ascens.unimore.robots.beh.CoopConstants
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.Ord
import fj.data.List
import fj.data.Stream
import fj.data.Zipper
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class ObstacleAvoidance {
	
	// taken from http://link.springer.com/chapter/10.1007%2F978-3-642-22907-7_7
	static def computeDirectionWithAvoidance(Double2D to, List<SensorReading> sensorReadings) {
		
		val sensorsAndLengthSq = sensorReadings.map[r|
			r -> r.dir.lengthSq
		]
		
		// this is the best I can get
		// I don't know why but it works better with -0.1
		val maxSq = sensorsAndLengthSq.map[value].maximum(Ord.doubleOrd)-0.1
		
		val vision = Zipper.fromStream(Stream.iterableStream(sensorsAndLengthSq)).some()
		
		val desiredDirection = vision.find[d|to.between(d.key.cone)].some()
		
		var gothroughR = desiredDirection
		var gothroughL = desiredDirection
		
		do {
			if (gothroughR.focus.value >= maxSq) {
				return gothroughR.chooseBest(maxSq, true)
			} else if (gothroughL.focus.value >= maxSq) {
				return gothroughL.chooseBest(maxSq, false)
			}
			gothroughR = gothroughR.cycle(true)
			gothroughL = gothroughL.cycle(false)
		} while ((gothroughR.focus != desiredDirection.focus)
			&& (gothroughL.focus != desiredDirection.focus))
		
		return desiredDirection.focus.key
	}
	
	private static def <A> chooseBest(Zipper<Pair<A, Double>> z, double maxSq, boolean toTheRight) {
		val prev = z.cycle(toTheRight)
		val prevprev = prev.cycle(toTheRight)
		val next = z.cycle(!toTheRight)
		val nextnext = next.cycle(!toTheRight)
		if (prev.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
			|| prevprev.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
		) {
			if (next.focus.value >= maxSq) {
				if (nextnext.focus.value >= maxSq) {
					return nextnext.focus.key
				}
				return next.focus.key
			}
		}
		if (next.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
			|| nextnext.focus.value < CoopConstants.AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
		) {
			if (prev.focus.value >= maxSq) {
				if (prevprev.focus.value >= maxSq) {
					return prevprev.focus.key
				}
				return prev.focus.key
			}
		}
		return z.focus.key
	}
	
	private static def <A> cycle(Zipper<A> z, boolean toTheRight) {
		if (toTheRight) z.cyclePrevious
		else z.cycleNext
	}
	
}