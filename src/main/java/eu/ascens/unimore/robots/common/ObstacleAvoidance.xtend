package eu.ascens.unimore.robots.common

import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.data.List
import fj.data.Option
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
	
	// taken from http://link.springer.com/chapter/10.1007%2F978-3-642-22907-7_7
	static def computeDirectionWithAvoidance(Double2D to, List<SensorReading> sensorReadings) {
		
		val vision = Zipper.fromStream(Stream.iterableStream(sensorReadings)).some()
		
		val desiredDirection = vision.find[d|to.between(d.cone)].some()
		
		if (desiredDirection.focus.isFree) {
			return Option.some(desiredDirection.focus)
		}
		
		var gothroughR = desiredDirection.cycle(true)
		var gothroughL = desiredDirection.cycle(false)
		
		while ((gothroughR.focus !== desiredDirection.focus)
				&& (gothroughL.focus !== desiredDirection.focus)) {
			
			if (gothroughR.focus.isFree) {
				return Option.some(gothroughR.chooseBest(true))
			} else if (gothroughL.focus.isFree) {
				return Option.some(gothroughL.chooseBest(false))
			}
			
			gothroughR = gothroughR.cycle(true)
			gothroughL = gothroughL.cycle(false)
		} 
		
		return Option.none
	}
	
	private static def isFree(SensorReading sr) {
		!sr.hasWall
		//sr.lengthSq >= SimulationConstants.WALL_RANGE_SQUARED
	}
	
	private static def chooseBest(Zipper<SensorReading> z, boolean toTheRight) {
		
		val next = z.cycle(toTheRight)
		val prev = z.cycle(!toTheRight)
		
		if (prev.focus.lengthSq < AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED
			&& !next.focus.hasWall) {
				return next.focus
		}
		
		return z.focus
	}
	
	private static def <A> cycle(Zipper<A> z, boolean toTheRight) {
		if (toTheRight) z.cyclePrevious
		else z.cycleNext
	}
	
}