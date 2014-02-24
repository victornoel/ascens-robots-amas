package eu.ascens.unimore.robots.beh.interfaces

import eu.ascens.unimore.robots.beh.datatypes.AgentSig
import eu.ascens.unimore.robots.beh.datatypes.Choice
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ReceivedExplorable
import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.data.List
import sim.util.Double2D
import eu.ascens.unimore.robots.mason.datatypes.VisibleVictim

interface IActions {
	
	def void goTo(Double2D to)
	
	def void broadcastExplorables(List<Explorable> explorables, boolean onVictim)
	
}

interface IActionsExtra extends IActions {
	
} 

interface IDecisions {
	
}

interface IDecisionsExtra extends IDecisions {
	
	def Choice lastChoice()
}

interface IRepresentations {
	
	def List<Explorable> explorables()
	
	def List<SeenVictim> seenVictims()
	
	def List<SeenVictim> consideredVictims()
	
}

interface IRepresentationsExtra extends IRepresentations {
	
	def List<Explorable> seenAreas()
	
	def List<Explorable> explorableFromOthers()
}

interface IPerceptions {
	
	def String myId()
	
	def List<SensorReading> visibleFreeAreas()
	
	def List<SensorReading> sensorReadings()
	
	def List<VisibleVictim> visibleVictims()
	
	def List<SensorReading> visibleWalls()
	
	def List<RBEmitter> visibleRobots()
	
	def Double2D escapeCrowdVector()
	
	def Double2D previousDirection()
	
	def boolean goingBack(Double2D dir)
}

interface IPerceptionsExtra extends IPerceptions {
	
	def Double2D lastMove()
}

interface IMessaging {
	
	def List<ReceivedExplorable> explorationMessages()
	
	def AgentSig currentSig()
	
}

interface IMessagingExtra extends IMessaging {
	
}