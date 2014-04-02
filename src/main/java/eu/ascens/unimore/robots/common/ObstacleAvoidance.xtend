package eu.ascens.unimore.robots.common

import eu.ascens.unimore.robots.SimulationConstants
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.data.List
import fj.data.Stream
import fj.data.Zipper
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class ObstacleAvoidance {
	
	// for these info, other agents do not rely on the fact
	// an agent use them
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE = 1.0
	// Useful constants based on the others
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED = AVOID_VERY_CLOSE_WALL_DISTANCE*AVOID_VERY_CLOSE_WALL_DISTANCE
	
	static def makeVision(List<SensorReading> sensorReadings) {
		Zipper.fromStream(Stream.iterableStream(sensorReadings)).some()
	}
	
	// taken from http://link.springer.com/chapter/10.1007%2F978-3-642-22907-7_7
	static def computeDirectionWithAvoidance(Double2D to, Zipper<SensorReading> vision) {
		
		val desiredDirection = vision.find[d|to.between(d.cone)].some()
		
		if (desiredDirection.focus.lengthSq >= SimulationConstants.WALL_RANGE_SQUARED) {
			return desiredDirection.focus
		}
		
		var gothroughR = desiredDirection.cycle(true)
		var gothroughL = desiredDirection.cycle(false)
		
		while ((gothroughR.focus !== desiredDirection.focus)
			&& (gothroughL.focus !== desiredDirection.focus)) {
			if (gothroughR.focus.lengthSq >= SimulationConstants.WALL_RANGE_SQUARED) {
				return gothroughR.chooseBest(true)
			} else if (gothroughL.focus.lengthSq >= SimulationConstants.WALL_RANGE_SQUARED) {
				return gothroughL.chooseBest(false)
			}
			gothroughR = gothroughR.cycle(true)
			gothroughL = gothroughL.cycle(false)
		} 
		
		return desiredDirection.focus
	}
	
	private static def chooseBest(Zipper<SensorReading> z, boolean toTheRight) {
		val prev = z.cycle(toTheRight)
		val next = z.cycle(!toTheRight)
		if (prev.focus.lengthSq < AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
			&& next.focus.lengthSq >= SimulationConstants.WALL_RANGE_SQUARED) {
			return next.focus
		} else if (next.focus.lengthSq < AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
			&&prev.focus.lengthSq >= SimulationConstants.WALL_RANGE_SQUARED) {
			return prev.focus
		} else {
			return z.focus
		}
	}
	
	private static def <A> cycle(Zipper<A> z, boolean toTheRight) {
		if (toTheRight) z.cyclePrevious
		else z.cycleNext
	}
	
}