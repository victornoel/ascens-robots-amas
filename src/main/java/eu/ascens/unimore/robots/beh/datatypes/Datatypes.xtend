package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*
import static extension fr.irit.smac.lib.contrib.xtend.JavaExtensions.*

@Data abstract class Choice {
	
	val Double2D direction
	
}

@Data class Explorable extends Choice {
	
	// used by decision
	val double criticality
	
	val double victimSlice
	
	// used by visu
	val Double2D via
	
	new(Double2D direction, double criticality, double victimSlice, Double2D via) {
		super(direction)
		doAssert(criticality >= 0 && criticality <= 1.0, "wrong crit: "+criticality)
		_criticality = criticality
		_victimSlice = victimSlice
		_via = via
	}
	
	new(Double2D direction, double criticality, double victimSlice) {
		this(direction, criticality, victimSlice, null)
	}
	
	def Explorable via(Double2D newDir, RBEmitter from, double newCriticality) {
		new Explorable(newDir, newCriticality, victimSlice, from.coord)
	}
	
	def Explorable withCriticality(double newCriticality) {
		new Explorable(direction, newCriticality, victimSlice, via)
	}
	
	override def toString() {
		"Expl["+criticality.toShortString(2)+","+direction.toShortString(2)+"]"
	}
}

@Data class SeenVictim extends Choice {
	
	/**
	 * How much people are around this victim (myself included)
	 */
	val int howMuch
	
	val int nbBotsNeeded
	
	val boolean ImNext
	
}

@Data class ReceivedExplorable {
	
	RBEmitter from
	Explorable explorable
	
	def toExplorable(Double2D newDir, double newCriticality) {
		explorable.via(newDir, from, newCriticality)
	}
	
}

@Data class AgentSig {
	
	val String id
	val int time
	
	override def toString() {
		"Sig("+ id + ","+ time + ")"
	}
}

@Data class ExplorableMessage extends Message {
	
	val List<Explorable> worthExplorable
	val boolean onVictim
	
}