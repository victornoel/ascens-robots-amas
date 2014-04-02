package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import fj.data.Option
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
	
	// used by visu
	val Option<RBEmitter> via
	val List<RBEmitter> counting
	
	val Option<String> gotItFrom
	val String origin
	
	val double traveled
	
	static def build(Double2D direction, double criticality, String origin) {
		new ExplorableImpl(direction, criticality, Option.none, List.nil, Option.none, origin, 0)
	}
	
	override def toString() {
		"Expl["+criticality.toShortString(2)+","+direction.toShortString(2)+"]"
	}
}

@Data class MySeenVictim extends SeenVictim {
	
	val boolean imResponsible
	
	static def fromSeenVictim(SeenVictim v, boolean imResponsible) {
		new MySeenVictim(
			v.direction,
			v.howMuch,
			v.nbBotsNeeded,
			v.imNext,
			v.inNeed,
			imResponsible
		)
	}
	
}

@Data class ReceivedExplorable {
	
	val RBEmitter from
	val Explorable explorable
	val boolean onVictim
	
	def Explorable toExplorable(Double2D newDir, double newCriticality, List<RBEmitter> counting) {
		new ExplorableImpl(newDir, newCriticality, Option.some(from), counting, Option.some(from.id), explorable.origin, explorable.traveled + from.coord.length)
	}
}

@Data class ExplorableMessage extends Message {
	
	val List<Explorable> worthExplorable
	val boolean onVictim
	
}