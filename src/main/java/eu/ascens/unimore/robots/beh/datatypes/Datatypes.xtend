package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.JavaExtensions.*

@Data abstract class Explorable {
	
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
	
	def sawMyself() {
		this.via == null
	}
	
	abstract def Explorable withSender(String sender)
	
	abstract def Explorable via(Double2D newDir, RBEmitter via)
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+direction.toShortString+"]"
	}
}

@Data class Victim extends Explorable {
		
	override withSender(String sender) {
		new Victim(direction,distance,origin,sender,howMuch,criticality,via)
	}
	
	override via(Double2D newDir, RBEmitter via) {
		new Victim(newDir, distance+via.coord.length, origin, via.id, howMuch, criticality, via.coord)
	}
	
	def minusOne() {
		new Victim(direction,distance,origin,sender,Math.max(0,howMuch-1),criticality,via)
	}
	
	def withHowMuch(int howMuch) {
		new Victim(direction,distance,origin,sender,Math.max(0,howMuch),criticality,via)
	}
	
}

@Data class Area extends Explorable {
	
	override withSender(String sender) {
		new Area(direction,distance,origin,sender,howMuch,criticality,via)
	}
	
	override via(Double2D newDir, RBEmitter via) {
		new Area(newDir, distance+via.coord.length, origin, via.id, howMuch, criticality, via.coord)
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
	
}