package eu.ascens.unimore.robots.mason.interfaces

import eu.ascens.unimore.robots.beh.datatypes.Choice
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import eu.ascens.unimore.robots.mason.datatypes.Stats
import eu.ascens.unimore.robots.mason.datatypes.VisibleVictim
import fj.data.List
import sim.util.Double2D

interface RobotMovements {
	
	def void setNextMove(Double2D m)
	
}

interface RobotPerceptions {
	
	def List<RBEmitter> getRBVisibleRobots()
	
	def List<SensorReading> getSensorReadings()
	
	def List<VisibleVictim> getVisibleVictims()
	
	def boolean isOutOfNest()
	
}

interface RobotVisu {
	
	def Choice choice()
	
	def Double2D move()
	
	def Iterable<Double2D> visibleBots()
	
	def Iterable<Explorable> explorables()
	
	def Iterable<SeenVictim> victimsFromMe()
	
	def Iterable<Explorable> areasOnlyFromMe()
	
	def Iterable<Explorable> explorablesFromOthers()
}

interface MasonControAndStats {
	
	def Stats getCurrentStats()
	
	def void startGUI()
	
	def void setup()
	
	def boolean step()
	
	def void shutdown()
	
}