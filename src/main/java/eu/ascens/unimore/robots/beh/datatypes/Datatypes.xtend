package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import fj.data.List

import static extension eu.ascens.unimore.robots.Utils.*

@Data class Explorable {
	
	val RelativeCoordinates coord
	val double criticality
	val double distance
	val String origin
	val int originTime
	
	def via(RBEmitter via) {
		new ExplorableWithSender(via.coord, criticality, distance+via.coord.value.length, origin, originTime, via.id)
	}
	
	def translateVia(RBEmitter via) {
		new ExplorableWithSender(coord, criticality, distance+via.coord.value.length, origin, originTime, via.id)
	}
	
	def hasSender(String sender) {
		false
	}
	
	def hasOrigin(String origin) {
		this.origin == origin
	}
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+coord+"]"
	}
}

@Data class ExplorableWithSender extends Explorable {
	
	val String sender
	
	override def toString() {
		"ExplS["+criticality.toShortString+","+distance.toShortString+","+coord+"]"
	}
	
	override hasSender(String sender) {
		this.sender == sender
	}
}

@Data class ExplorableMessage extends Message {
	
	val List<Explorable> worthExplorable
	
}