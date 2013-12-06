package eu.ascens.unimore.robots.beh.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableWithSender
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair
import sim.util.Double2D
import eu.ascens.unimore.robots.mason.datatypes.SensorReading

interface IActions {
	
	def void goTo(Double2D to)
	
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
	
	def List<Explorable> explorableFromOthers()
}

interface IPerceptions {
	
	def String myId()
	
	def List<Pair<String, Pair<Double2D, Double2D>>> visionConesCoveredByVisibleRobots()
	
	def List<SensorReading> visibleFreeAreas()
	
	def List<Double2D> visibleVictims()
	
	def List<SensorReading> visibleWalls()
	
	def List<RBEmitter> visibleRobots()
	
	def Double2D escapeCrowdVector()
	
	def Double2D previousDirection()
	
	def boolean goingBack(Double2D dir)
}

interface IPerceptionsExtra extends IPerceptions {
	
	def Double2D lastChoice()
	
	def Double2D lastMove()
}

interface IMessaging {
	
	def List<Pair<RBEmitter, List<ExplorableWithSender>>> explorationMessages()
	
	def ExplorableWithSender explorableWithSender(Explorable e)
	
	def Explorable newSeenExplorable(Double2D coord, double criticality)
	
}

interface IMessagingExtra extends IMessaging {
	
}