package eu.ascens.unimore.robots.geometry

import com.vividsolutions.jts.algorithm.Angle
import fj.Ord
import fj.Ordering
import java.util.Comparator
import org.eclipse.xtext.xbase.lib.Pair
import org.eclipse.xtext.xbase.lib.Pure
import sim.util.Double2D

class GeometryExtensions {
	
	@Pure
	static def toShortString(double d) {
		(((d*100) as int as double)/100).toString
	}
	
	// if used with sort on list, will gives vectors in counter-clockwise order
	// starting from (1,0)
	public static val Comparator<Double2D> COMPARATOR_D2D = [e1,e2|e1.compare(e2)]
	public static val Comparator<RelativeCoordinates> COMPARATOR_RC = [e1,e2|e1.compareTo(e2)]
	
	public static val Ord<Double2D> ORD_D2D = Ord.ord([e1|[e2|
		val x = e1.compare(e2)
		// copied from Ord.comparableOrd
		if (x < 0) Ordering.LT else if (x == 0) Ordering.EQ else Ordering.GT
	]])
	
	public static val Ord<RelativeCoordinates> ORD_RC = Ord.comparableOrd
	
	// return a normalised vector
	@Pure
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
	
	/*
    	> 0 if b is clockwise from a
    	< 0 if a is clockwise from b
    	0 if a and b are collinear
	 */
	// from https://github.com/mikolalysenko/compare-slope/blob/master/slope.js
	@Pure
	static def compare(Double2D a, Double2D b) {
		val d = quadrant(a) - quadrant(b)
		if (d != 0) { // different quadrants
			d
		} else {
			// p-q is the wedge product
			val p = a.x * b.y
			val q = a.y * b.x
			if (p > q) -1
			else if (p < q) 1 
			else 0
		}
	}
	
	@Pure
	private static def quadrant(Double2D it) {
		if (x > 0) {
			if (y >= 0) {
				return 1
			} else {
				return 4
			}
		} else if (x < 0) {
			if (y >= 0) {
				return 2
			} else {
				return 3
			}
		} else if (y > 0) {
			return 1
		} else if (y < 0) {
			return 3
		}
		return 0
	}
	
	@Pure
	static def beforeIncluding(Double2D what, Double2D from) {
		compare(what, from) <= 0
	}
	
	@Pure
	static def beforeStrict(Double2D what, Double2D from) {
		compare(what, from) < 0
	}
	
	@Pure
	static def afterStrict(Double2D what, Double2D to) {
		!beforeIncluding(what, to)
	}
	
	@Pure
	static def afterIncluding(Double2D what, Double2D to) {
		!beforeStrict(what, to)
	}
	
	@Pure
	static def between(Double2D what, Pair<Double2D, Double2D> p) {
		between(what, p.key, p.value)
	}
	
	@Pure
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