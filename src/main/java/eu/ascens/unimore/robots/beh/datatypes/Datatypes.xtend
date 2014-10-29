package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import eu.ascens.unimore.robots.mason.datatypes.Message
import fj.data.List
import fj.data.Option
import org.eclipse.xtend.lib.annotations.Data
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*
import static extension fr.irit.smac.lib.contrib.xtend.JavaExtensions.*

interface Explorable extends Choice {
	
	def double getCriticality()
	def Option<String> getGotItFrom()
	def String getOrigin()
	def double getTraveled()
	
}

@Data class ExplorableImpl implements Explorable {
	
	// used by decision
	val Double2D direction
	
	val double criticality
	val Option<String> gotItFrom
	val String origin
	val double traveled
	
	static def build(Double2D direction, double criticality, String origin) {
		new ExplorableImpl(direction, criticality, Option.none, origin, 0)
	}
	
	override toString() {
		"Expl["+criticality.toShortString(2)+","+direction.toShortString(2)+"]"
	}
}

@Data class ExplorableFromVictim extends ExplorableImpl {
	
	val SeenVictim relatedVictim
	
	static def build(Double2D direction, double criticality, String origin, SeenVictim v) {
		new ExplorableFromVictim(direction, criticality, Option.none, origin, 0, v)
	}
}

@Data class ExplorableFromOther extends ExplorableImpl {
	
	// used by visu
	val Double2D via
	val List<Double2D> counting
	
}

@Data class ReceivedExplorable {
	
	val Double2D from
	val String fromId
	val Explorable explorable
	val boolean onVictim
	
	def Explorable toExplorable(Double2D newDir, double newCriticality, List<Double2D> counting) {
		new ExplorableFromOther(newDir, newCriticality, Option.some(fromId), explorable.origin, explorable.traveled + from.length, from, counting)
	}
}

@Data class ExplorableMessage extends Message {
	val List<Explorable> worthExplorable
	val boolean onVictim
	
	// TODO this is needed because there seems to be a bug…
	// See https://bugs.eclipse.org/bugs/show_bug.cgi?id=449185
	new(List<Explorable> worthExplorable, boolean onVictim) {
		this.worthExplorable = worthExplorable
		this.onVictim = onVictim
	}
}