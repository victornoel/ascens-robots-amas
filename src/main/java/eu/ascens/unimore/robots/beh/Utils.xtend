package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import fj.Equal
import fj.Ord
import fj.data.List

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

class Utils {
	
	public static val criticalityOrd = Ord.doubleOrd
	public static val criticalityEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= CoopConstants.CRITICALITY_PRECISION
	]]
	
	public static val explorableCriticalityOrd = criticalityOrd.comap[Explorable e|e.criticality]
	public static val explorableCriticalityEq = criticalityEq.comap[Explorable e|e.criticality]
	
	@Pure
	static def keepMaxEquivalent(List<Explorable> l) {
		l.maximums(explorableCriticalityEq, explorableCriticalityOrd)
	}
}