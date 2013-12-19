package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import fj.Equal
import fj.Ord
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pure

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class Utils {
	
	public static val criticalityOrd = Ord.doubleOrd
	public static val criticalityEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= Constants.CRITICALITY_PRECISION
	]]
	
	public static def <E extends Explorable> explorableCriticalityOrd() { criticalityOrd.comap[E e|e.criticality] }	
	public static def <E extends Explorable> explorableCriticalityEq() { criticalityEq.comap[E e|e.criticality] }
	public static def <E extends Explorable> explorableOriginEq() { Equal.stringEqual.comap[E e|e.origin.id] }
	public static def <E extends Explorable> explorableOriginOrd() { Ord.stringOrd.comap[E e|e.origin.id] }
	
	public static val crowdOrd = Ord.doubleOrd
	public static val crowdEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= 0.1
	]]
	
	@Pure
	static def <E extends Explorable> maxEquivalentCriticalities(List<E> l) {
		l.maximums(explorableCriticalityEq,	explorableCriticalityOrd)
	}
	
	@Pure
	static def <E extends Explorable> maxEquivalentOriginTimestamp(List<E> l) {
		l.maximums(Equal.intEqual.comap[E e|e.origin.time], Ord.intOrd.comap[E e|e.origin.time])
	}
}