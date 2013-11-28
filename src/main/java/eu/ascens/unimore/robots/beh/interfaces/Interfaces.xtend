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

interface IPerceptions {
	
	def List<RelativeCoordinates> wallsFromMe()
	
	def List<Pair<String, RelativeCoordinates>> conesCoveredByVisibleRobots()
	
	def List<Pair<RBEmitter, ExplorableMessage>> explorationMessages()
	
	def List<Pair<RelativeCoordinates, Boolean>> sensorReadings()
	
	def List<RelativeCoordinates> visibleVictims()
	
	def List<RBEmitter> visibleRobots()
}