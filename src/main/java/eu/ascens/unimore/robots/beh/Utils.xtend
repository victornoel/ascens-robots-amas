package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.geometry.RelativeCoordinates
import fj.Equal
import fj.Ord
import fj.data.List
import java.util.Map
import org.eclipse.xtext.xbase.lib.Pair
import org.eclipse.xtext.xbase.lib.Pure
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class Utils {
	
	public static val VISION_RANGE_SQUARED = Constants.VISION_RANGE*Constants.VISION_RANGE
	public static val RB_RANGE_SQUARED = Constants.RB_RANGE*Constants.RB_RANGE
	public static val OBSTACLE_AVOID_RANGE_SQUARED = Constants.OBSTACLE_AVOID_TARGET_DISTANCE*Constants.OBSTACLE_AVOID_TARGET_DISTANCE
	
	public static val criticalityOrd = Ord.doubleOrd
	public static val distanceOrd = Ord.doubleOrd
	public static val criticalityEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= 0.01
	]]
	public static val originEq = Equal.stringEqual
	
	public static def <E extends Explorable> explorableCriticalityOrd() { criticalityOrd.comap[E e|e.criticality] }	
	public static def <E extends Explorable> explorableCriticalityEq() { criticalityEq.comap[E e|e.criticality] }
	public static def <E extends Explorable> explorableDistanceOrd() { distanceOrd.comap[E e|e.distance] }
	public static def <E extends Explorable> explorableOriginEq() { originEq.comap[E e|e.origin] }
	
	public static val crowdOrd = Ord.doubleOrd
	public static val crowdEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= 0.2
	]]
	
	@Pure
	static def <K, V> Map<K, V> toMap(Iterable<? extends Pair<? extends K, ? extends V>> pairs) {
		val result = newLinkedHashMap()
		for (p : pairs) {
			result.put(p.key, p.value)
		}
		result
	}
	
	@Pure
	static def <E extends Explorable> maxEquivalentCriticalities(List<E> l) {
		l.maximums(explorableCriticalityEq,	explorableCriticalityOrd)
	}
	
	static def <E extends Explorable> maxEquivalentTimestamp(List<E> l) {
		l.maximums(Equal.intEqual.comap[E e|e.originTime], Ord.intOrd.comap[E e|e.originTime])
	}
	
	@Pure
	static def <E extends Explorable> keepOnePerOrigin(List<E> in) {
		in.group(explorableOriginEq)
			.map[maxEquivalentTimestamp.minimum(explorableDistanceOrd)]
	}
	
	// inspired from http://buildnewgames.com/vector-field-collision-avoidance/
	@Pure
	static def computeDirectionWithAvoidance(RelativeCoordinates target, Iterable<RelativeCoordinates> obstacles) {
		val v = new MutableDouble2D(target.value.resize(Constants.OBSTACLE_AVOID_TARGET_DISTANCE))
		for(o: obstacles) {
			val lsq = o.value.lengthSq
			if (lsq < OBSTACLE_AVOID_RANGE_SQUARED) {
				v.subtractIn(o.value.resize(1.0/lsq))
			}
		}
		RelativeCoordinates.of(new Double2D(v))
	}
	
	@Pure
	static def computeCrowdVector(Iterable<RelativeCoordinates> bots) {
		val v = new MutableDouble2D(0,0)
		for(o: bots) {
			val lsq = o.value.lengthSq
			v.subtractIn(o.value.resize(1.0/lsq))
		}
		RelativeCoordinates.of(new Double2D(v))
	}
	
	// take the perpendicular in the middle of the vector
	// and return the start and the end of the arc of desired radius
	// intersecting with this perpendicular and of center 0,0
	@Pure
	static def computeConeCoveredByBot(RelativeCoordinates c, double radiusSq) {
		val half = c.value.multiply(1.0/2.0)
		val hlSq = half.lengthSq
		val l = if (hlSq > 0) {
			if (hlSq < radiusSq) {
				Math.sqrt(radiusSq - hlSq)
			} else {
				1
			}
		} else {
			0.0
		}
		val cL = c.length
		// from http://stackoverflow.com/a/3349134
		val rotRight = new Double2D((l*c.value.y)/cL, -(l*c.value.x)/cL)
		val start = half.add(rotRight) // compute start of its covered area for us
		val end = half.subtract(rotRight) // compute start of its covered area for us
		RelativeCoordinates.of(c.value, start -> end)
	}
}