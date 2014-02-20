package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.JavaExtensions.*

@Data abstract class Choice {
	
	val Double2D direction
	
}

@Data class Explorable extends Choice {
	
	// used by messaging
	// it is the distance the message has travelled
	val double distance
	
	// used by messaging
	val AgentSig origin
	val String sender
	
	// used by decision
	val double criticality
	
	// used by visu
	val Double2D via
	
	new(Double2D direction, double distance, AgentSig origin, String sender, double criticality, Double2D via) {
		super(direction)
		_distance = distance
		_origin = origin
		_sender = sender
		_criticality = criticality
		_via = via
	}
	
	new(Double2D direction, AgentSig origin, double criticality) {
		this(direction, 0, origin, null, criticality, null)
	}
	
	def hasSender(String sender) {
		this.sender == sender
	}
	
	def hasOrigin(String origin) {
		this.origin.id == origin
	}
	
	def sawMyself() {
		this.via == null
	}
	
	def Explorable via(Double2D newDir, RBEmitter from) {
		via(newDir, from, criticality)
	}
	
	def Explorable via(Double2D newDir, RBEmitter from, double newCriticality) {
		new Explorable(newDir, distance+from.coord.length, origin, from.id, newCriticality, from.coord)
	}
	
	def Explorable withCriticality(double newCriticality) {
		new Explorable(direction, distance, origin, sender, newCriticality, via)
	}
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+direction.toShortString+"]"
	}
}

@Data class VisibleVictim extends Choice {
	
	/**
	 * How much people are around this victim (myself included)
	 */
	val int howMuch
	
	val boolean ImNext
	
}

@Data class ReceivedExplorable {
	
	RBEmitter from
	Explorable explorable
	int fromHowMany
	
	def withHowManyMore(int howManyMore) {
		new ReceivedExplorable(from, explorable, fromHowMany+howManyMore)
	}
	
	def toExplorable(Double2D newDir) {
		explorable.via(newDir, from)
	}
	
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