package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*

@Data class Explorable {
	
	val Double2D direction
	val double distance
	
	val AgentSig origin
	
	val String sender
	
	// not used
	val int howMuch
	
	val double criticality
	
	// used by visu
	val Double2D via
	
	def hasSender(String sender) {
		this.sender == sender
	}
	
	def hasOrigin(String origin) {
		this.origin.id == origin
	}
	
	def withSender(String sender) {
		new Explorable(direction,distance,origin,sender,howMuch,criticality,via)
	}
	
	def via(Double2D newDir, RBEmitter via) {
		new Explorable(newDir, distance+via.coord.length, origin, via.id, 0, criticality, via.coord)
	}
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+direction.toShortString+"]"
	}
}

@Data class AgentSig {
	
	val String id
	val int time
	
	override def toString() {
		"Sig("+ id + ","+ time ")"
	}
}

@Data class ExplorableMessage extends Message {
	
	val List<Explorable> worthExplorable
	
}