package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import java.util.Map

import static extension eu.ascens.unimore.robots.Utils.*
import fj.data.List

abstract class Explorable {
	
	@Property val RelativeCoordinates coord
	@Property val double criticality
	var boolean isVia = false
	var List<Explorable> replaces = List.nil
	
	new(RelativeCoordinates coord, double criticality) {
		this._coord = coord
		this._criticality = criticality
	}
	
	override def toString() {
		type + (if (isVia) "(via)" else "") + "["+criticality.toShortString+","+coord+"]"
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
	def aggregates(RelativeCoordinates coord, List<Explorable> replaces) {
		buildNew(coord,criticality) => [n|
			n.isVia = true
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