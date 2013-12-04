package eu.ascens.unimore.robots.mason.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableWithSender
import eu.ascens.unimore.robots.geometry.RelativeCoordinates
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
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
	
	def RelativeCoordinates choice()
	
	def Iterable<RelativeCoordinates> visibleBots()
	
	def Iterable<Explorable> explorables()
	
	def Iterable<Explorable> explorablesOnlyFromMe()
	
	def Iterable<ExplorableWithSender> explorablesFromOthers()
}