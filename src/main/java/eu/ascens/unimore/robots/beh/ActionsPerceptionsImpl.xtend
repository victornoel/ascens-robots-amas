package eu.ascens.unimore.robots.beh

import com.google.common.collect.EvictingQueue
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IActionsExtra
import eu.ascens.unimore.robots.beh.interfaces.IPerceptionsExtra
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import java.util.Queue
import org.eclipse.xtext.xbase.lib.Pair
import org.slf4j.LoggerFactory
import sim.util.Double2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.robots.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class ActionsPerceptionsImpl extends ActionsPerceptions implements IActionsExtra, IPerceptionsExtra {

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
	
	override lastChoice() {
		lastChoice
	}
	
	var lastChoice = RelativeCoordinates.of(new Double2D(0,0))
	
	override broadcastExplorables(List<Explorable> explorables) {
		requires.rbBroadcast.push(
			new ExplorableMessage(
				explorables
			)
		)
	}
	
	// this is a kind of AVT but for 2D?
	val Queue<Double2D> prevDirs = EvictingQueue.create(4)
	
	@StepCached
	override previousDirection() {
		val pd = new MutableDouble2D()
		
		var i = 1
		for(d: prevDirs) {
			pd.addIn(d.resize(i))
			i = i+1
		}
		
		RelativeCoordinates.of(new Double2D(pd))
	}
	
	override goingBack(RelativeCoordinates dir) {
		dir.dot(previousDirection) < 0
	}
	
	override goTo(RelativeCoordinates to) {
		
		if (to.value.lengthSq > 0) {
			// TODO: smooth things using prevDirs? like not moving if it's useless
			val move = to.computeDirectionWithAvoidance(wallsFromMe)
			
			logger.info("going to {} targetting {}.", move, to)
			requires.move.setNextMove(move)
		}
		lastChoice = to
		prevDirs.offer(to.value)
	}
	
	override myId() {
		requires.id.pull
	}
	
	// must ABSOLUTELY be cached since requires.RBMessages.pull
	// empty the message box
	@StepCached(forceEnable=true)
	private def rbMessages() {
		requires.RBMessages.pull.toFJList
			=> [
				logger.debug("rbMessages: {}", it)
			]
	}
	
	@StepCached
	private def wallsFromMe() {
		sensorReadings
			.filter[value]
			.map[key]
	}

	@StepCached
	override sensorReadings() {
		requires.see.sensorReadings
			=> [
				logger.info("sensorReadings: {}", it)
			]
	}
	
	@StepCached
	override visibleRobots() {
		requires.see.RBVisibleRobots
			=> [
				logger.info("visibleRobots: {}", it)
			]
	}
	
	@StepCached
	override visibleVictims() {
		requires.see.visibleVictims
			=> [
				logger.info("visibleVictims: {}", it)
			]
	}

	@StepCached
	override visionConesCoveredByVisibleRobots() {
		visibleRobots.map[id -> coord.computeConeCoveredByBot(VISION_RANGE_SQUARED)]
	}
	
	@StepCached
	override escapeCrowdVector() {
		visibleRobots.map[coord].computeCrowdVector
	}
	
	var List<Pair<RBEmitter, ExplorableMessage>> pastMessages = List.nil
	
	// force because it changes pastMessages
	// and relies on rbMessages which is also force
	// so can be called only once per turn
	@StepCached(forceEnable=true)
	override explorationMessages() {
		
		// I should have only one message from each robot TODO check
		val expl = rbMessages.filter[
			val m = message
			switch m {
				ExplorableMessage case emitter.coord.value.lengthSq > 0: true
				default: false
			}
		]
		
		val toRemove = newHashSet() => [s|
			s += expl.map[emitter.id]
			logger.info("got new messages from {}", s)
		]
		val toKeep = newHashSet() => [s|
			s += visibleRobots.map[id]
		]
		
		pastMessages = pastMessages.filter[m|
			!toRemove.contains(m.key.id) && toKeep.contains(m.key.id) 
		] + expl.map[
			emitter -> (message as ExplorableMessage)
		]
		
		pastMessages
	}
	
}
