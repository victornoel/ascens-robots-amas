package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.geometry.RelativeCoordinates
import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*

@Data class Explorable {
	
	val RelativeCoordinates coord
	val double criticality
	val double distance
	val String origin
	val int originTime
	
	def via(RBEmitter via) {
		new ExplorableWithSender(via.coord, criticality, distance+via.coord.length, origin, originTime, via, via.id)
	}
	
	def translatedVia(RBEmitter via) {
		val vd = via.coord.length
		val nc = {
			val c = coord+via.coord
			if (c.lengthSq == 0) {
				(coord*0.01)+via.coord
			} else {
				c
			}
		}
		new ExplorableWithSender(nc.resize(vd), criticality, distance+vd, origin, originTime, via, via.id)
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
	
	val RBEmitter via
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