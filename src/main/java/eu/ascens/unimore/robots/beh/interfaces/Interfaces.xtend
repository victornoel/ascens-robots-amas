package eu.ascens.unimore.robots.beh.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ReceivedExplorable
import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import eu.ascens.unimore.robots.mason.datatypes.VisibleVictim
import fj.data.List
import sim.util.Double2D

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
		
	def List<ReceivedExplorable> receivedMessages()
}

interface IPerceptionsExtra extends IPerceptions {
	
	def Double2D lastMove()
}