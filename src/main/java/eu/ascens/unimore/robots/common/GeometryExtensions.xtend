package eu.ascens.unimore.robots.common

import fj.Equal
import fj.Ord
import fj.Ordering
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class GeometryExtensions {
	
	/**
	 * if used with sort on list, will gives vectors
	 * in counter-clockwise order starting from (1,0)
	 */
	public static val Ord<Double2D> ORD_D2D = Ord.ord([e1|[e2|
		val x = e1.compare(e2)
		// copied from Ord.comparableOrd
		if (x < 0) Ordering.LT else if (x == 0) Ordering.EQ else Ordering.GT
	]])
	
	public static val crowdOrd = Ord.doubleOrd
	public static val crowdEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= 0.1
	]]
	
	// inspired from http://buildnewgames.com/vector-field-collision-avoidance/
	@Pure
	public static def computeCrowdVector(Iterable<Double2D> bots) {
		val v = new MutableDouble2D(0,0)
		for(o: bots) {
			val lsq = o.lengthSq
			if (lsq > 0) {
				v -= o.resize(1.0/lsq)
			}
		}
		new Double2D(v)
	}
	
	@Pure
	public static def computeVectorSum(Iterable<Double2D> bots) {
		val v = new MutableDouble2D(0,0)
		for(o: bots) {
			v += o
		}
		new Double2D(v)
	}
	
	@Pure
	public static def isCloserThanMe(Double2D him, double hisDistToDirSq, double myDistToDirSq) {
		hisDistToDirSq < myDistToDirSq
			|| (hisDistToDirSq == myDistToDirSq
				// in case we have the same dist, take the one the more on the east
				// or if same the more on the south
				&& (him.x > 0 || (him.x == 0 && him.y > 0))
			)
	}
}