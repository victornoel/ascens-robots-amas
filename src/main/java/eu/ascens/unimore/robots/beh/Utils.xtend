package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableWithSender
import fj.Equal
import fj.Ord
import fj.data.List
import java.util.Map
import org.eclipse.xtext.xbase.lib.Pair
import org.eclipse.xtext.xbase.lib.Pure
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

class Utils {
	
	public static val criticalityOrd = Ord.doubleOrd
	public static val distanceOrd = Ord.doubleOrd
	public static val criticalityEq = Equal.equal [double a|[double b|
		Math.abs(a - b) <= Constants.CRITICALITY_PRECISION
	]]
	
	public static def <E extends Explorable> explorableCriticalityOrd() { criticalityOrd.comap[E e|e.criticality] }	
	public static def <E extends Explorable> explorableCriticalityEq() { criticalityEq.comap[E e|e.criticality] }
	public static def <E extends Explorable> explorableDistanceOrd() { distanceOrd.comap[E e|e.distance] }
	public static def <E extends Explorable> explorableOriginEq() { Equal.stringEqual.comap[E e|e.origin.id] }
	public static def <E extends Explorable> explorableOriginOrd() { Ord.stringOrd.comap[E e|e.origin.id] }
	public static def <E extends ExplorableWithSender> explorableSenderEq() { Equal.stringEqual.comap[E e|e.sender.id] }
	public static def <E extends ExplorableWithSender> explorableSenderOrd() { Ord.stringOrd.comap[E e|e.sender.id] }
	
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
	static def <K, V> V getOr(Map<K, V> m, K key, V or) {
		val r = m.get(key)
		if (r == null) {
			or
		} else r
	}
	
	@Pure
	static def <E extends Explorable> maxEquivalentCriticalities(List<E> l) {
		l.maximums(explorableCriticalityEq,	explorableCriticalityOrd)
	}
	
	@Pure
	static def <E extends Explorable> maxEquivalentOriginTimestamp(List<E> l) {
		l.maximums(Equal.intEqual.comap[E e|e.origin.time], Ord.intOrd.comap[E e|e.origin.time])
	}
	
	@Pure
	static def <E extends ExplorableWithSender> maxEquivalentSenderTimestamp(List<E> l) {
		l.maximums(Equal.intEqual.comap[E e|e.sender.time], Ord.intOrd.comap[E e|e.sender.time])
	}
	
	@Pure
	static def <E extends Explorable> keepOnePerOrigin(List<E> in) {
		in.sort(explorableOriginOrd)
			.group(explorableOriginEq)
			.map[
				// maybe not needed since we already clean in messaging
//				val a = maxEquivalentOriginTimestamp
//				a.
				val m = minimum(explorableDistanceOrd)
				new Explorable(m.direction, m.distance, m.origin, it.length, m.criticality, m.via)
			]
	}
	
	@Pure
	static def <E extends ExplorableWithSender> keepOnePerSender(List<E> in) {
		in.sort(explorableSenderOrd)
			.group(explorableSenderEq)
			.map[
				val m = maxEquivalentSenderTimestamp
				if (m.tail.notEmpty) throw new RuntimeException("should have one msg per sender/timestamp.")
				m.head
			]
	}
	
	// inspired from http://buildnewgames.com/vector-field-collision-avoidance/
	@Pure
	static def computeCrowdVector(Iterable<Double2D> bots) {
		val v = new MutableDouble2D(0,0)
		for(o: bots) {
			val lsq = o.lengthSq
			if (lsq > 0) {
				v.subtractIn(o.resize(1.0/lsq))
			}
		}
		new Double2D(v)
	}
	
	// take the perpendicular in the middle of the vector
	// and return the start and the end of the arc of desired radius
	// intersecting with this perpendicular and of center 0,0
	@Pure
	static def computeConeCoveredByBot(Double2D c, double radiusSq) {
		val half = c/2.0
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
		val m = l/c.length
		// from http://stackoverflow.com/a/3349134
		val rotRight = new Double2D(c.y*m, -c.x*m)
		val start = half.add(rotRight) // compute start of its covered area for us
		val end = half.subtract(rotRight) // compute start of its covered area for us
		start -> end
	}	
}