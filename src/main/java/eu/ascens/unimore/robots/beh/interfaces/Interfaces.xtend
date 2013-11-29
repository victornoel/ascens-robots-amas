package eu.ascens.unimore.robots.beh.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair

interface IActions {
	
	def void goTo(RelativeCoordinates to)
	
	def void broadcastExplorables(List<Explorable> explorables)
	
}

interface IActionsExtra extends IActions {
	
} 

interface IDecisions {
	
}

interface IDecisionsExtra extends IDecisions {
	
	def RelativeCoordinates lastChoice()
	
}

interface IRepresentations {
	
	def List<Explorable> explorables()
	
}

interface IRepresentationsExtra extends IRepresentations {
	
	def List<Explorable> explorableVictims()
	
	def List<Explorable> explorableFromMe()
	
	def List<Explorable> explorableOnlyFromMe()
	
	def List<Explorable> explorableFromOthers()
}

interface IPerceptions {
	
	def String myId()
	
	def List<Pair<String, RelativeCoordinates>> conesCoveredByVisibleRobots()
	
	def List<Pair<RBEmitter, ExplorableMessage>> explorationMessages()
	
	def List<Pair<RelativeCoordinates, Boolean>> sensorReadings()
	
	def List<RelativeCoordinates> visibleVictims()
	
	def List<RBEmitter> visibleRobots()
}

interface IPerceptionsExtra extends IPerceptions {
	
	def List<RelativeCoordinates> wallsFromMe()
	
}