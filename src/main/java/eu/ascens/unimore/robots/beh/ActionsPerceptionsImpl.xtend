package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IActions
import eu.ascens.unimore.robots.beh.interfaces.IPerceptions
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.Utils.*
import eu.ascens.unimore.robots.beh.datatypes.Explorable

class ActionsPerceptionsImpl extends ActionsPerceptions implements IActions, IPerceptions {

	val logger = LoggerFactory.getLogger("agent")

	override protected make_preStep() {
		[|preStep]
	}
	
	@Step
	def preStep() {}
	
	override protected make_actions() {
		this
	}
	
	override protected make_perceptions() {
		this
	}
			
	override broadcastExplorables(List<Explorable> explorables) {
		requires.rbBroadcast.push(new ExplorableMessage(explorables, conesCoveredByVisibleRobots.toMap))
	}
	
	override goTo(RelativeCoordinates to) {
		
		val move = to.computeDirectionWithAvoidance(provides.perceptions.wallsFromMe)
		
		logger.info("going to {} targetting {}.", move, to)
		requires.move.setNextMove(move)
	}
	
	@StepCached(forceEnable=true)
	private def rbMessages() {
		val res = List.iterableList(requires.RBMessages.pull)
		logger.debug("rbMessages: {}", res)
		res
	}
	
	@StepCached
	override wallsFromMe() {
		sensorReadings
			.filter[value]
			.map[key]
	}

	@StepCached
	override sensorReadings() {
		val res = requires.see.sensorReadings
		logger.info("sensorReadings: {}", res)
		res
	}
	
	@StepCached
	override visibleRobots() {
		val res = requires.see.RBVisibleRobots
		logger.info("visibleRobots: {}", res)
		res
	}
	
	@StepCached
	override visibleVictims() {
		requires.see.visibleVictims
	}
	
	static val VISION_RANGE_SQUARED = Constants.VISION_RANGE*Constants.VISION_RANGE
		
	@StepCached
	override conesCoveredByVisibleRobots() {
		// consider all visible bots
		visibleRobots.map[id -> coord.value.computeConeCoveredByBot(VISION_RANGE_SQUARED)]
	}
	
	@StepCached
	override explorationMessages() {
		// I should have only one message from each robot TODO check
		val res = rbMessages.filter[
			val m = message
			switch m {
				ExplorableMessage case emitter.coord.value.lengthSq > 0: true
				default: false
			}
		].map[
			emitter -> (message as ExplorableMessage)
		]
		
		if (logger.infoEnabled) {
			logger.info("got messages from {}", res.map[key.id])
		}
		
		res
	}
	
}
