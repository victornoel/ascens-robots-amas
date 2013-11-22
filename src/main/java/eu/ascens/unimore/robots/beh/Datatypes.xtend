package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import fj.data.List
import java.util.Map

import static extension eu.ascens.unimore.robots.Utils.*

abstract class Explorable {
	
	@Property val RelativeCoordinates coord
	@Property val double criticality
	var String via = null
	var List<Explorable> replaces = List.nil
	
	new(RelativeCoordinates coord, double criticality) {
		this._coord = coord
		this._criticality = criticality
	}
	
	override def toString() {
		type + (if (via != null) "("+via+")" else "") + "["+criticality.toShortString+","+coord+"]"
	}
	
	abstract protected def String type()
	
	abstract protected def Explorable buildNew(RelativeCoordinates coord, double criticality)
	
	/** 
	 * remove all internal data that are not meant to be communicated
	 * to other agents
	 */
	def clean() {
		val res = buildNew(coord,criticality)
		if (res == null) throw new RuntimeException
		res
	}
	
	/**
	 * 
	 */
	def aggregates(RBEmitter emitter, List<Explorable> replaces) {
		buildNew(emitter.coord,criticality) => [n|
			n.via = emitter.id
			n.replaces = replaces
		]
	}
	
}

class VictimRepresentation extends Explorable {
	
	new(RelativeCoordinates coord) {
		// TODO reduce if there is a lot of people around?
		this(coord, Constants.STARTING_VICTIM_CRITICALITY)
	}
	
	private new(RelativeCoordinates coord, double criticality) {
		super(coord, criticality)
	}
	
	override protected type() {
		"Vict"
	}
	
	override protected buildNew(RelativeCoordinates coord, double criticality) {
		new VictimRepresentation(coord, criticality)
	}
	
}

class SeenExplorableRepresentation extends Explorable {
	
	new(RelativeCoordinates coord) {
		// reduce criticality of visible place where I come from?
		// TODO maybe smooth it a little?
		super(coord, Constants.STARTING_EXPLORABLE_CRITICALITY)
	}
	
	private new(RelativeCoordinates coord, double criticality) {
		super(coord, criticality)
	}
	
	override protected type() {
		"Expl"
	}
	
	override protected buildNew(RelativeCoordinates coord, double criticality) {
		new SeenExplorableRepresentation(coord, criticality)
	}
	
}


@Data class ExplorableMessage extends Message {
	
	List<Explorable> worthExplorable
	Map<String, RelativeCoordinates> others
	
}

@Data class ExplorableMessage2 extends Message {
	
	// TODO add a measure of what is available there
	//boolean explorable
	boolean onlyFromMe
	boolean fromOthers
}

@Data class GoingMessage extends Message {
	
	RelativeCoordinates goingToward
	Map<String, RelativeCoordinates> others
	
}