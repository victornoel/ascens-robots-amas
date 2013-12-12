package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*

@Data class Explorable {
	
	val Double2D direction
	val double distance
	
	val MessageSignature origin
	
	val int howMuch
	
	val double criticality
	
	val Double2D via
	
	def withSender(String sender, int senderTime) {
		new ExplorableWithSender(direction, distance, origin, 0, criticality, null, new MessageSignature(sender, senderTime))
	}
	
	def hasSender(String sender) {
		false
	}
	
	def hasOrigin(String origin) {
		this.origin.id == origin
	}
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+direction.toShortString+"]"
	}
}

@Data class MessageSignature {
	
	val String id
	val int time
	
	override def toString() {
		"Sig("+ id + ","+ time ")"
	}
}

@Data class ExplorableWithSender extends Explorable {
	
	val MessageSignature sender
	
	override hasSender(String sender) {
		this.sender.id == sender
	}
	
	def via(Double2D newDir, RBEmitter via) {
		new Explorable(newDir, distance+via.coord.length, origin, 0, criticality, via.coord)
	}
}

@Data class ExplorableMessage extends Message {
	
	val List<ExplorableWithSender> worthExplorable
	
}