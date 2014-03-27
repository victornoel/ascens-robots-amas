package eu.ascens.unimore.robots.geometry

import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import fj.Equal
import fj.Ord
import fj.Ordering
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import fj.data.List

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
	
	/**
	 * First tries to secure before trying to go
	 * For another victim: the idea is that a saved victim
	 * is more important than two discovered victims
	 */
	@Pure
	public static def mostImportantVictim(List<SeenVictim> victims) {
		victims.maximum(
			Ord.doubleOrd.comap[SeenVictim it|
				val hm = howMuch - (if (imNext) 1 else 0)
				(hm as double)/(nbBotsNeeded as double)
			] || Ord.doubleOrd.comap[SeenVictim it|-direction.lengthSq]
		)
	}
	
	/**
	 * Consider first victims in most need
	 */
	@Pure
	public static def mostInNeedVictim(List<SeenVictim> victims) {
		victims.maximum(
			Ord.doubleOrd.comap[SeenVictim it|
				val hm = howMuch - (if (imNext) 1 else 0)
				(hm as double)/(nbBotsNeeded as double)
			] || Ord.doubleOrd.comap[SeenVictim it|-direction.lengthSq]
		)
	}
	
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