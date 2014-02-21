package eu.ascens.unimore.robots.geometry

import com.vividsolutions.jts.algorithm.Angle
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair
import sim.util.Double2D

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.JavaExtensions.*

class Radiangle {
	
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
	@Property double value
	
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
	
	def toNormalizedVector() {
		new Double2D(1, 0).rotate(value)
	}
	
	// is it counter clockwise?
	// includes to but not from
	def between(Radiangle from, Radiangle to) {
		between(from.value, to.value)
	}
	
	// includes to but not from
	def between(double from, double to) {
		if (from <= to) {
			from < value && value <= to
		} else {
			value <= to || from < value
		}
	}
	
	override toString() {
		"Rad["+value.toShortString+"]"
	}
	
}