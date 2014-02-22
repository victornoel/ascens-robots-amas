package eu.ascens.unimore.robots.geometry

import eu.ascens.unimore.robots.Constants
import fj.Ord
import fj.Ordering
import java.util.Comparator
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class GeometryExtensions {
	
	// if used with sort on list, will gives vectors in counter-clockwise order
	// starting from (1,0)
	public static val Comparator<Double2D> COMPARATOR_D2D = [e1,e2|e1.compare(e2)]
	
	public static val Ord<Double2D> ORD_D2D = Ord.ord([e1|[e2|
		val x = e1.compare(e2)
		// copied from Ord.comparableOrd
		if (x < 0) Ordering.LT else if (x == 0) Ordering.EQ else Ordering.GT
	]])
	
	public static val SENSORS_DIRECTIONS_CONES =
		Radiangle.buildCones(Constants.NB_WALL_SENSORS).map[
			val cone = it.key.toNormalizedVector -> it.value.toNormalizedVector
			middleAngledVector(cone.key, cone.value) -> cone
		].sort(ORD_D2D.comap[Pair<Double2D, Pair<Double2D, Double2D>> it|key]) // sort evaluates
		
	
}