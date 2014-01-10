package eu.ascens.unimore.robots.beh.datatypes

import eu.ascens.unimore.robots.mason.datatypes.Message
import fj.data.List
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.JavaExtensions.*

@Data abstract class Explorable {
	
	val Double2D direction
	val double distance
	
	val AgentSig origin
	
	val String sender
	
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
	
	abstract def Explorable via(Double2D newDir, String fromId, Double2D fromCoord)
	
	override def toString() {
		"Expl["+criticality.toShortString+","+distance.toShortString+","+direction.toShortString+"]"
	}
}

@Data class Victim extends Explorable {
	
	val int howMuch
	
	override via(Double2D newDir, String fromId, Double2D fromCoord) {
		new Victim(newDir, distance+fromCoord.length, origin, fromId, criticality, fromCoord, howMuch)
	}
	
	def withHowMuch(int howMuch) {
		new Victim(direction,distance,origin,sender,criticality,via,howMuch)
	}
	
}

@Data class Area extends Explorable {
		
	override via(Double2D newDir, String fromId, Double2D fromCoord) {
		new Area(newDir, distance+fromCoord.length, origin, fromId, criticality, fromCoord)
	}
}

@Data class ReceivedExplorable {
	
	String fromId
	Double2D fromCoord
	Explorable explorable
	int fromHowMany
	
	def withHowManyMore(int howManyMore) {
		new ReceivedExplorable(fromId, fromCoord, explorable, fromHowMany+howManyMore)
	}
	
	def toExplorable(Double2D newDir) {
		explorable.via(newDir, fromId, fromCoord)
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