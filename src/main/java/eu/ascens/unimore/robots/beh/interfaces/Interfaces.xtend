package eu.ascens.unimore.robots.beh.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableWithSender
import eu.ascens.unimore.robots.geometry.RelativeCoordinates
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
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
	
}

interface IRepresentations {
	
	def List<Explorable> explorables()
	
}

interface IRepresentationsExtra extends IRepresentations {
	
	def List<Explorable> explorableVictims()
	
	def List<Explorable> responsibleVictims()
	
	def List<Explorable> explorableSeen()
	
	def List<Explorable> responsibleSeen()
	
	def List<ExplorableWithSender> explorableFromOthers()
}

interface IPerceptions {
	
	def String myId()
	
	def List<Pair<String, RelativeCoordinates>> visionConesCoveredByVisibleRobots()
	
	def List<Pair<RBEmitter, List<Explorable>>> explorationMessages()
	
	def List<Pair<RelativeCoordinates, Boolean>> sensorReadings()
	
	def List<RelativeCoordinates> visibleVictims()
	
	def List<RelativeCoordinates> visibleWalls()
	
	def List<RBEmitter> visibleRobots()
	
	def RelativeCoordinates escapeCrowdVector()
	
	def RelativeCoordinates previousDirection()
	
	def boolean goingBack(RelativeCoordinates dir)
}

interface IPerceptionsExtra extends IPerceptions {
	
	def RelativeCoordinates lastChoice()
	
}