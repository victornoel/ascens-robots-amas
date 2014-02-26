package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IActionsExtra
import eu.ascens.unimore.robots.beh.interfaces.IPerceptionsExtra
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import eu.ascens.unimore.robots.mason.datatypes.VisibleVictim
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import org.slf4j.LoggerFactory
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.robots.geometry.ObstacleAvoidance.*

class ActionsPerceptionsImpl extends ActionsPerceptions implements IActionsExtra, IPerceptionsExtra {

	val logger = LoggerFactory.getLogger("agent")

	override protected make_preStep() {
		[|preStep]
	}
	
	@StepCached
	def void preStep() {}
	
	override protected make_actions() {
		this
	}
	
	override protected make_perceptions() {
		this
	}
	
	override lastMove() {
		lastMove
	}
	
	var lastMove = new Double2D(0,0)
	
	override broadcastExplorables(List<Explorable> explorables, boolean onVictim) {
		requires.rbPublish.push(new ExplorableMessage(explorables, onVictim))
	}
	
	override previousDirection() {
		lastMove
	}
	
	override goingBack(Double2D dir) {
		dir.dot(previousDirection) < 0
	}
	
	override goTo(Double2D to) {
		val l = to.length
		if (l > 0.01) {			
			// TODO: smooth things using prevDirs? like not moving if it's useless
			val move = to.computeDirectionWithAvoidance(sensorReadings).dir.resize(l)
			lastMove = to
			
			logger.info("going to {} targetting {}.", move, to)
			requires.move.setNextMove(move)
		}
	}
	
	override myId() {
		requires.id.pull
	}
	
	@Cached
	override List<SensorReading> visibleFreeAreas() {
		sensorReadings
			.filter[!hasWall]
	}
	
	@Cached
	override List<SensorReading> visibleWalls() {
		sensorReadings
			.filter[hasWall]
	}

	@Cached
	override List<SensorReading> sensorReadings() {
		requires.see.sensorReadings
			=> [logger.info("sensorReadings: {}", it)]
	}
	
	@Cached
	override List<RBEmitter> visibleRobots() {
		requires.see.RBVisibleRobots
			=> [logger.info("visibleRobots: {}", it)]
	}
	
	@Cached
	override List<VisibleVictim> visibleVictims() {
		requires.see.visibleVictims
			=> [logger.info("visibleVictims: {}", it)]
	}
	
	@Cached
	override Double2D escapeCrowdVector() {
		visibleRobots
		// TODO I could also just keep those as close as victims
		// and check with visible victims...
		.filter[
			message.isNone
			|| !(message.some() instanceof ExplorableMessage)
			|| !(message.some() as ExplorableMessage).onVictim
		]
		.map[coord]
		.computeCrowdVector
	}
}
