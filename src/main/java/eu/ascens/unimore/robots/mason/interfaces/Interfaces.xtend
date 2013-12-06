package eu.ascens.unimore.robots.mason.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.data.List
import sim.util.Double2D

interface RobotMovements {
	
	def void setNextMove(Double2D m)
	
}

interface RobotPerceptions {
	
	def List<RBEmitter> getRBVisibleRobots()
	
	// bool is true if it is a wall
	def List<SensorReading> getSensorReadings()
	
	def List<Double2D> getVisibleVictims()
	
}

interface RobotVisu {
	
	def Double2D choice()
	
	def Double2D move()
	
	def Iterable<Double2D> visibleBots()
	
	def Iterable<Explorable> explorables()
	
	def Iterable<Explorable> explorablesOnlyFromMe()
	
	def Iterable<Explorable> explorablesFromOthers()
}