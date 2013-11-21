package eu.ascens.unimore.robots.mason.datatypes

import com.vividsolutions.jts.algorithm.Angle
import eu.ascens.unimore.robots.Constants
import fj.Function
import fj.Ord
import fj.Ordering
import java.util.Comparator
import org.eclipse.xtext.xbase.lib.Pair
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.Utils.*
import fj.data.List

@Data class Radiangle implements Comparable<Radiangle> {
	
	public static val PI_OVER_8 = Angle.PI_OVER_4 / 2.0
	
	/*
	public static val NORTH = of(Angle.PI_OVER_2)
	public static val SOUTH = of(-Angle.PI_OVER_2)
	public static val EAST = of(0)
	public static val WEST = of(Math.PI)
	public static val NORTHEAST = of(Angle.PI_OVER_4)
	public static val NORTHWEST = of(3*Angle.PI_OVER_4)
	public static val SOUTHEAST = of(-Angle.PI_OVER_4)
	public static val SOUTHWEST = of(-3*Angle.PI_OVER_4)
	
	public static val NORTHNORTHEAST = of(3.0 * PI_OVER_8)
	public static val NORTHEASTEAST = of(PI_OVER_8)
	public static val SOUTHEASTEAST = of(-PI_OVER_8)
	public static val SOUTHSOUTHEAST = of(-3.0 * PI_OVER_8)
	public static val SOUTHSOUTHWEST = of(-5.0 * PI_OVER_8)
	public static val SOUTHWESTWEST = of(-7.0 * PI_OVER_8)
	public static val NORTHWESTWEST = of(7.0 * PI_OVER_8)
	public static val NORTHNORTHWEST = of(5.0 * PI_OVER_8)
	*/
	
	// in counter clockwise order
	/*
	public static val DIRECTIONS = #[EAST, NORTHEAST, NORTH, NORTHWEST, WEST, SOUTHWEST, SOUTH, SOUTHEAST]
	public static val DIRECTIONS2 = #[NORTHEASTEAST, NORTHNORTHEAST, NORTHNORTHWEST, NORTHWESTWEST, SOUTHWESTWEST, SOUTHSOUTHWEST, SOUTHSOUTHEAST, SOUTHEASTEAST]
	public static val DIRECTIONS3 = (DIRECTIONS + DIRECTIONS2).sortBy[value]
	*/
	
//	static def buildDirections(int nbDirections) {
//		(0..<nbDirections).map[i|
//			// center of the slice
//			sliceMiddle(nbDirections, i)
//		]
//	}
	
	static def buildCones(int nbDirections) {
		var r = List.nil
		var Radiangle prev = sliceStart(nbDirections,0)
		for(i: 1..<nbDirections) {
			val current = sliceStart(nbDirections,i)
			r = r.cons(prev -> current)
			prev = current
		}
		r = r.cons(prev -> sliceStart(nbDirections,0))
		r
	}
	
//	static def buildDirectionsWithCones(int nbDirections) {
//		buildCones(nbDirections).map[c|
//			Radiangle.middle(c) -> c
//		]
//	}
	
	// w.r.t. a plan where the North is toward (0,1) and the east toward (1,0)
	// (0,0) being the South-West corner of the plan
	// always between -Pi excluded and Pi
	double value
	
	private new(double value) {
		this._value = Angle.normalize(value)
	}
	
	static def of(double v) {
		new Radiangle(v)
	}
	
	// gives the center of the slice corresponding to this index
	// index starts at 0 for angle 0 to Angle.PI_TIMES_2/ofMany
	static def sliceMiddle(int ofMany, int index) {
		of(sliceWidth(ofMany)*(2*index+1)/2)
	}
	
	static def sliceStart(int ofMany, int index) {
		of(sliceWidth(ofMany)*index)
	}
	
	static def sliceWidth(int ofMany) {
		Angle.PI_TIMES_2/ofMany
	}
	
	// return the index of this angle
	// TODO check for the boundaries… there may be something wrong
	def unslice(int ofMany) {
		unslice(value, ofMany)
	}
	
	static def unslice(double angle, int ofMany) {
		(Angle.normalizePositive(angle)/sliceWidth(ofMany)) as int
	}
	
	def inverse() {
		of(value+Math.PI)
	}
	
	def minus(double a) {
		of(value-a)
	}
	
	def around(double howMuch) {
		val step = howMuch/2
		minus(step) -> plus(step)
	}
	
	// wrong, see Utils.getMiddleAngledVector
//	static def middle(Pair<Radiangle,Radiangle> p) {
//		Radiangle.of((p.key.value+p.value.value)/2)
//	}
	
	def plus(double a) {
		of(value+a)
	}
	
	def between(Pair<Radiangle,Radiangle> p) {
		between(p.key, p.value)
	}
	
	// is it counter clockwise?
	// includes to but not from
	def between(Radiangle from, Radiangle to) {
		between(from.value, to.value)
	}
	
	// includes to but not from
	def between(double from, double to) {
		if (from < to) {
			from < value && value <= to
		} else {
			value <= to || from < value
		}
	}
	
	override compareTo(Radiangle o) {
		val r = value - o.value
		// TODO what about precision?!
		if (r < 0) -1 else if (r > 0) 1 else 0 
	}
	
	override toString() {
		"Rad["+value.toShortString+"]"
	}
	
	def static void main(String[] args) {
//		for(i : 0..<24) {
//			val a = Radiangle.slice(24, i)
//			val b = Radiangle.unslice(a.value, 24)
//			println(i+":"+a+"="+b)
//		}
//		for(a: DIRECTIONS) {
//			println(a)
//		}
//		for(a: DIRECTIONS2) {
//			println(a)
//		}
//		for(a: DIRECTIONS3) {
//			println(a)
//		}
	}
	
}

@Data class RelativeCoordinates implements Comparable<RelativeCoordinates> {
	
	/*
	public static val NORTH = of(PolarCoordinates.of(Radiangle.NORTH, 1))
	public static val SOUTH = of(PolarCoordinates.of(Radiangle.SOUTH, 1))
	public static val EAST = of(PolarCoordinates.of(Radiangle.EAST, 1))
	public static val WEST = of(PolarCoordinates.of(Radiangle.WEST, 1))
	public static val NORTHEAST = of(PolarCoordinates.of(Radiangle.NORTHEAST, 1))
	public static val NORTHWEST = of(PolarCoordinates.of(Radiangle.NORTHWEST, 1))
	public static val SOUTHEAST = of(PolarCoordinates.of(Radiangle.SOUTHEAST, 1))
	public static val SOUTHWEST = of(PolarCoordinates.of(Radiangle.SOUTHWEST, 1))
	
	public static val NORTHNORTHEAST = of(PolarCoordinates.of(Radiangle.NORTHNORTHEAST, 1))
	public static val NORTHEASTEAST = of(PolarCoordinates.of(Radiangle.NORTHEASTEAST, 1))
	public static val SOUTHEASTEAST = of(PolarCoordinates.of(Radiangle.SOUTHEASTEAST, 1))
	public static val SOUTHSOUTHEAST = of(PolarCoordinates.of(Radiangle.SOUTHSOUTHEAST, 1))
	public static val SOUTHSOUTHWEST = of(PolarCoordinates.of(Radiangle.SOUTHSOUTHWEST, 1))
	public static val SOUTHWESTWEST = of(PolarCoordinates.of(Radiangle.SOUTHWESTWEST, 1))
	public static val NORTHWESTWEST = of(PolarCoordinates.of(Radiangle.NORTHWESTWEST, 1))
	public static val NORTHNORTHWEST = of(PolarCoordinates.of(Radiangle.NORTHNORTHWEST, 1))
		
	public static val DIRECTIONS_CONES = Radiangle.DIRECTIONS.zipWithCones
	public static val DIRECTIONS2_CONES = Radiangle.DIRECTIONS2.zipWithCones
	public static val DIRECTIONS3_CONES = Radiangle.DIRECTIONS3.zipWithCones
	*/
	
	/**
	 * 
	 */
	public static val SENSORS_DIRECTIONS_CONES = Radiangle.buildCones(Constants.NB_WALL_SENSORS).map[
			val cone = of(it.key).value -> of(it.value).value
			of(cone)
		].sort(SlopeComparator.ORD_RC) // sort evaluates
	
	Double2D value
	Pair<Double2D,Double2D> cone
	
	static def of(Double2D vector, Pair<Double2D,Double2D> cone) {
		return new RelativeCoordinates(vector, cone)
	}
	
	static def of(Pair<Double2D,Double2D> cone) {
		return new RelativeCoordinates(cone.middleAngledVector, cone)
	}
	
	static def of(Radiangle rad) {
		of(PolarCoordinates.of(rad, 1))
	}
	
	static def of(Double2D vector) {
		return of(vector, null)
	}
	
	static def of(PolarCoordinates pc) {
		of(pc.toVector)
	}
	
	def multiply(double s) {
		of(value.multiply(s), cone)
	}
	
	override compareTo(RelativeCoordinates o) {
		SlopeComparator.INSTANCE_D2D.compare(value, o.value)
	}
	
	def beforeIncluding(Double2D from) {
		beforeIncluding(value, from)
	}
	
	def beforeStrict(Double2D from) {
		beforeStrict(value, from)
	}
	
	def afterStrict(Double2D to) {
		afterStrict(value, to)
	}
	
	def afterIncluding(Double2D to) {
		afterIncluding(value, to)
	}
	
	def between(Double2D from, Double2D to) {
		value.between(from, to)
	}
	
	def between(RelativeCoordinates from, RelativeCoordinates to) {
		value.between(from.value, to.value)
	}
	
	def between(Pair<RelativeCoordinates, RelativeCoordinates> p) {
		value.between(p.key.value, p.value.value)
	}
	
	override toString() {
		"Rel["+value.x.toShortString+","+value.y.toShortString+"]"
	}
}

@Data class PolarCoordinates {
	
	Radiangle angle
	double distance
	
	static def of(Double2D vector) {
		of(Radiangle.of(vector.angle), vector.length)
	}
	
	static def of(Radiangle a, double d) {
		new PolarCoordinates(a, d)
	}
	
	def toVector() {
		new Double2D(distance, 0).rotate(angle.value)
	}
	
	override toString() {
		"Polar["+distance.toShortString+","+angle+"]"
	}
	
}

@Data class Message {
	
}

@Data class RBMessage {
	RBEmitter emitter
	Message message
}

@Data class RBEmitter {
	RelativeCoordinates coord
	String id
}

class SlopeComparator implements Comparator<Double2D> {
	
	public static val ORD_D2D = Ord.ord(Function.curry([e1,e2|
		val c = INSTANCE_D2D.compare(e1,e2)
		// copied from Ord.doubleOrd
		if (c < 0) Ordering.LT else if (c == 0) Ordering.EQ else Ordering.GT
	]))
	
	public static val ORD_RC = ORD_D2D.comap[RelativeCoordinates c|c.value]
//	Ord.ord(Function.curry([RelativeCoordinates e1, RelativeCoordinates e2|
//		ORD_D2D.compare(e1.value, e2.value)
//	]))
	
	// if used with sort on list, will gives vectors in counter-clockwise order
	// starting from (1,0)
	public static val Comparator<Double2D> INSTANCE_D2D = new SlopeComparator
	public static val Comparator<RelativeCoordinates> INSTANCE_RC = [e1,e2|INSTANCE_D2D.compare(e1.value, e2.value)]
	
	private new() {}
	
	/*
    	> 0 if b is clockwise from a
    	< 0 if a is clockwise from b
    	0 if a and b are collinear
	 */
	// from https://github.com/mikolalysenko/compare-slope/blob/master/slope.js
	override compare(Double2D a, Double2D b) {
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
	
	private def quadrant(Double2D it) {
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
}