package eu.ascens.unimore.robots.geometry

import com.vividsolutions.jts.algorithm.Angle
import eu.ascens.unimore.robots.Constants
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair
import org.eclipse.xtext.xbase.lib.Pure
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

@Data class Radiangle implements Comparable<Radiangle> {
	
	static def buildCones(int nbDirections) {
		// this is mutable, careful
		var r = List.Buffer.empty
		var Radiangle prev = sliceStart(nbDirections,0)
		for(i: 1..<nbDirections) {
			val current = sliceStart(nbDirections,i)
			r += (prev -> current)
			prev = current
		}
		r += (prev -> sliceStart(nbDirections,0))
		r.toList
	}
	
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
	
}

class RelativeCoordinates implements Comparable<RelativeCoordinates> {
	
	public static val SENSORS_DIRECTIONS_CONES =
		Radiangle.buildCones(Constants.NB_WALL_SENSORS).map[
			val cone = of(it.key).value -> of(it.value).value
			of(cone)
		].sort(ORD_RC) // sort evaluates
	
	@Property val Double2D value
	@Property val Pair<Double2D,Double2D> cone
	
	private new(Double2D value, Pair<Double2D,Double2D> cone) {
		this._value = value
		this._cone = cone
	}
	
	@Pure
	static def of(Double2D vector, Pair<Double2D,Double2D> cone) {
		return new RelativeCoordinates(vector, cone)
	}
	
	@Pure
	static def of(Pair<Double2D,Double2D> cone) {
		return new RelativeCoordinates(cone.middleAngledVector, cone)
	}
	
	@Pure
	static def of(Radiangle rad) {
		of(PolarCoordinates.of(rad, 1))
	}
	
	@Pure
	static def of(Double2D vector) {
		return of(vector, null)
	}
	
	@Pure
	static def of(PolarCoordinates pc) {
		of(pc.toVector)
	}
	
	@Pure
	def length() {
		value.length
	}
	
	@Pure
	def lengthSq() {
		value.lengthSq
	}
	
	@Pure
	def distanceSq(RelativeCoordinates o) {
		value.distanceSq(o.value)
	}
	
	@Pure
	def distance(RelativeCoordinates o) {
		value.distance(o.value)
	}
	
	@Pure
	def negate() {
		of(value.negate)
	}
	
	@Pure
	def dot(RelativeCoordinates o) {
		value.dot(o.value)
	}
	
	@Pure
	def resize(double s) {
		of(value.resize(s), cone)
	}
	
	@Pure
	def multiply(double s) {
		of(value.multiply(s), cone.key.multiply(s) -> cone.value.multiply(s))
	}
	
	@Pure
	def operator_multiply(double s) {
		multiply(s)
	}
	
	@Pure
	def add(RelativeCoordinates p) {
		of(p.value.add(value))
	}
	
	@Pure
	def operator_plus(RelativeCoordinates p) {
		add(p)
	}
	
	@Pure
	def subtract(RelativeCoordinates p) {
		of(p.value.subtract(value))
	}
	
	@Pure
	def operator_minus(RelativeCoordinates p) {
		subtract(p)
	}
	
	@Pure
	override compareTo(RelativeCoordinates o) {
		value.compare(o.value)
	}
	
	@Pure
	def beforeIncluding(Double2D from) {
		beforeIncluding(value, from)
	}
	
	@Pure
	def beforeStrict(Double2D from) {
		beforeStrict(value, from)
	}
	
	@Pure
	def afterStrict(Double2D to) {
		afterStrict(value, to)
	}
	
	@Pure
	def afterIncluding(Double2D to) {
		afterIncluding(value, to)
	}
	
	@Pure
	def between(Double2D from, Double2D to) {
		value.between(from, to)
	}
	
	@Pure
	def between(RelativeCoordinates from, RelativeCoordinates to) {
		value.between(from.value, to.value)
	}
	
	@Pure
	def between(Pair<RelativeCoordinates, RelativeCoordinates> p) {
		value.between(p.key.value, p.value.value)
	}
	
	@Pure
	def between(RelativeCoordinates c) {
		value.between(c.cone.key, c.cone.value)
	}
	
	@Pure
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