package eu.ascens.unimore.robots

import com.vividsolutions.jts.algorithm.Angle
import eu.ascens.unimore.robots.beh.Explorable
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.robots.mason.datatypes.SlopeComparator
import fj.F
import fj.Ord
import fj.Ordering
import fj.data.List
import java.util.Map
import org.eclipse.xtext.xbase.lib.Pair
import sim.util.Double2D
import sim.util.MutableDouble2D

class Utils {
	
	public static val strictCriticalityOrd = Ord.ord([ double a|[ double b|
		Ord.doubleOrd.compare(a, b);
	]])
	
	public static val criticalityOrd = Ord.ord([ double a|[ double b|
		if (Math.abs(a - b) <= 0.01) Ordering.EQ
		else strictCriticalityOrd.compare(a, b);
	]])
	
	public static val explorableCriticalityOrd = criticalityOrd.comap[Explorable e|e.criticality]
	public static val strictExplorableCriticalityOrd = strictCriticalityOrd.comap[Explorable e|e.criticality]	
	
	static def toShortString(double d) {
		(((d*100) as int as double)/100).toString
	}
	
	static def <K, V> Map<K, V> toMap(Iterable<? extends Pair<? extends K, ? extends V>> pairs) {
		val result = newLinkedHashMap()
		for (p : pairs) {
			result.put(p.key, p.value)
		}
		result
	}
	
	static def <A> count(List<A> l, F<A, Boolean> f) {
		var xs = l
		var i = 0
		while (xs.notEmpty) {
			val h = xs.head
			if (f.f(h)) {
				i = i+1
			}
			xs = xs.tail
		}
		i
	}
	
	// TODO check if order is problematic
//	static def <A,B> inbetween(List<Pair<A,B>> in) {
//		if (in.empty) #[]
//		else {
//			val List<Pair<B, A>> _l = List.nil
//			val Pair<A,B> _p = null
//			val preRes = in.foldLeft([p,e|
//				val nl = if (p.key != null) {
//					p.value.cons(p.key.value -> e.key)
//				} else p.value
//				e -> nl
//			], _p -> _l)
//			preRes.value.cons(preRes.key.value -> in.head.key)
//		}
//	}
	
	// return a normalised vector
	static def Double2D getMiddleAngledVector(Pair<Double2D, Double2D> p) {
		val from = p.key
		val to = p.value
		// dot product:
		// <0 if they are opposite
		// >0 if they are in the same direction
		val d = from.dot(to)
		// wedge product: is 0 if they are colinear
		val w = from.perpDot(to)
		val v = if (d < 0 && w == 0) {
			from.rotate(Angle.PI_OVER_2)
		} else if (d > 0 && w == 0) {
			from
		} else {
			// dot sign gives us the correct direction
			from.add(to).multiply(w)
		}
		v.normalize
	}
	
	// inspired from http://buildnewgames.com/vector-field-collision-avoidance/
	static def computeDirectionWithAvoidance(RelativeCoordinates target, Iterable<RelativeCoordinates> obstacles) {
		val v = new MutableDouble2D(target.value.resize(Constants.OBSTACLE_AVOID_TARGET_DISTANCE))
		for(o: obstacles) {
			val lsq = o.value.lengthSq
			if (lsq < Constants.OBSTACLE_AVOID_RANGE_SQUARED) {
				v.subtractIn(o.value.resize(1.0/lsq))
			}
		}
		RelativeCoordinates.of(new Double2D(v))
	}
	
	// take the perpendicular in the middle of the vector
	// and return the start and the end of the arc of desired radius
	// intersecting with this perpendicular and of center 0,0
	static def computeConeCoveredByBot(Double2D c, double radiusSq) {
		val half = c.multiply(1.0/2.0)
		val hlSq = half.lengthSq
		// if they are separated from more than twice the radius
		// the cone would be actually empty
		if (hlSq > 0 && hlSq < radiusSq) {
			val l = Math.sqrt(radiusSq - hlSq)
			val cL = c.length
			// from http://stackoverflow.com/a/3349134
			val rotRight = new Double2D((l*c.y)/cL, -(l*c.x)/cL)
			val start = half.add(rotRight) // compute start of its covered area for us
			val end = half.subtract(rotRight) // compute start of its covered area for us
			RelativeCoordinates.of(c, start -> end)
		} else {
			RelativeCoordinates.of(c, c -> c)
		}
	}
	
	// compute the direction of the whatFromHim based on his perception of me
	// TODO it's missing something about the fact that we may not have the same
	// plane of reference…
	// translateFromHimToMe is not correct if the basis for both bot was different...
	static def translateFromAToB(Double2D whatFromA, Double2D AFromB, Double2D BFromA) {
		whatFromA.subtract(BFromA)
	}
	
	static def beforeIncluding(Double2D what, Double2D from) {
		SlopeComparator.INSTANCE_D2D.compare(what, from) <= 0
	}
	
	static def beforeStrict(Double2D what, Double2D from) {
		SlopeComparator.INSTANCE_D2D.compare(what, from) < 0
	}
	
	static def afterStrict(Double2D what, Double2D to) {
		!beforeIncluding(what, to)
	}
	
	static def afterIncluding(Double2D what, Double2D to) {
		!beforeStrict(what, to)
	}
	
	static def between(Double2D what, Pair<Double2D, Double2D> p) {
		between(what, p.key, p.value)
	}
	
	static def between(Double2D what, Double2D from, Double2D to) {
		// two cases:
		// 1) from is before to in counter clockwise and 2) to is before from
		if (from.beforeIncluding(to)) {
			// -Pi ------ F ********** T ------- Pi
			what.afterStrict(from) && what.beforeIncluding(to)
		} else {
			// -Pi ******* T ---------- F ******* Pi
			what.beforeIncluding(to) || what.afterStrict(from)
		}
	}
}