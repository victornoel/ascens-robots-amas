package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import fj.Equal
import fj.Ord
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pure

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import eu.ascens.unimore.robots.beh.datatypes.Victim

class Utils {
	
	public static val criticalityOrd = Ord.doubleOrd
	public static val criticalityEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= Constants.CRITICALITY_PRECISION
	]]
	
	public static def <E extends Explorable> explorableCriticalityOrd() { criticalityOrd.comap[E e|e.criticality] }	
	public static def <E extends Explorable> explorableCriticalityEq() { criticalityEq.comap[E e|e.criticality] }
	
	public static val crowdOrd = Ord.doubleOrd
	public static val crowdEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= 0.1
	]]
	
	@Pure
	static def <E extends Explorable> maxEquivalentCriticalities(List<E> l) {
		l.maximums(explorableCriticalityEq,	explorableCriticalityOrd)
	}
	
	@Pure
	static def <E extends Explorable> keepEquivalent(List<E> l) {
		l.takeWhile[e|
			explorableCriticalityEq.eq(l.head,e)
			&& switch e {
				Victim: {
					Ord.booleanOrd.eq(l.head.sawMyself,e.sawMyself)
					&& Ord.doubleOrd.eq(l.head.distance,e.distance)
				}
				default: true
			}
		]
	}
	
	@Pure
	static def <E extends Explorable> orderByDescendingCriticality(List<E> l) {
		l.sort(
			explorableCriticalityOrd.inverse
			.orThen(Ord.booleanOrd.comap[E e|!e.sawMyself])
			.orThen(Ord.doubleOrd.comap[E e|e.distance])
		)
	}
}