package eu.ascens.unimore.robots.mason.interfaces

import eu.ascens.unimore.robots.beh.Explorable
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair

interface RobotMovements {
	
	def void setNextMove(RelativeCoordinates m)
	
}

interface RobotPerceptions {
	
	def List<RBEmitter> getRBVisibleRobots()
	
	// bool is true if it is a wall
	def List<Pair<RelativeCoordinates, Boolean>> getSensorReadings()
	
	def List<RelativeCoordinates> getVisibleVictims()
	
}

interface RobotVisu {
	
	def RelativeCoordinates getLastChoice()
	
	def Iterable<RelativeCoordinates> visibleBots()
	
	def Iterable<Explorable> consideredExplorable()
	
	def Iterable<Explorable> consideredExplorableOnlyFromMe()
	
	def Iterable<Explorable> consideredExplorableFromOthers()
}