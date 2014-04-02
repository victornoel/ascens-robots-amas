package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import fj.Equal
import fj.F
import fj.Ord
import fj.data.List

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

class Utils {
	
	public static val criticalityOrd = Ord.doubleOrd
	public static val criticalityEq = Equal.doubleEqual
//	Equal.equal [double a|[double b|
//		Math.abs(a - b) <= CoopConstants.CRITICALITY_PRECISION
//	]]
	
	@Pure
	static def keepMaxEquivalents(List<Explorable> l) {
		keepMaxEquivalents(l, [criticality])
	}
	
	@Pure
	static def <E> keepMaxEquivalents(List<E> l, F<E, Double> f) {
		l.maximums(criticalityEq.comap(f), criticalityOrd.comap(f))
	}
}