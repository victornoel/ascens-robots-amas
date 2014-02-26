package eu.ascens.unimore.robots.geometry

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
	
}