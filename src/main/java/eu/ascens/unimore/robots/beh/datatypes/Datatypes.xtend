package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

@Data class Explorable {
	
	val Double2D coord
	val double criticality
	val double distance
	val String origin
	val int originTime
	
	def withSender(String sender, int senderTime) {
		new ExplorableWithSender(coord, criticality, distance, origin, originTime, sender, senderTime)
	}
	
	def hasSender(String sender) {
		false
	}
	
	def hasOrigin(String origin) {
		this.origin == origin
	}
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+coord.toShortString+"]"
	}
}

@Data class ExplorableWithSender extends Explorable {
	
	val String sender
	val int senderTime
		
	def via(RBEmitter via) {
		new Explorable(via.coord, criticality, distance+via.coord.length, origin, originTime)
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
		new Explorable(nc.resize(vd), criticality, distance+vd, origin, originTime)
	}
	
	override hasSender(String sender) {
		this.sender == sender
	}
}

@Data class ExplorableMessage extends Message {
	
	val List<ExplorableWithSender> worthExplorable
	
}