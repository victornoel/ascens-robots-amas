package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.datatypes.ExplorableWithSender
import eu.ascens.unimore.robots.beh.interfaces.IMessagingExtra
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import java.util.Map
import org.eclipse.xtext.xbase.lib.Pair
import org.slf4j.LoggerFactory
import sim.util.Double2D

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class MessagingImpl extends Messaging implements IMessagingExtra {

	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_messaging() {
		this
	}
	
	override protected make_preStep() {
		[|preStep]
	}
	
	var int timestamp = 0
	
	@Step
	def preStep() {
		timestamp = timestamp + 1
	}
	
	var List<Pair<RBEmitter, List<ExplorableWithSender>>> pastMessages = List.nil
	val Map<String, Integer> times = newHashMap
	
	// must ABSOLUTELY be cached since requires.RBMessages.pull
	// empty the message box
	@StepCached(forceEnable=true)
	override explorationMessages() {
		
		val rbMsgs = requires.RBMessages.pull.toFJList
		
		// I should have only one message from each robot TODO check
		val expl = rbMsgs.map[rbM|
			val m = rbM.message
			rbM.emitter -> switch m {
				ExplorableMessage case rbM.emitter.coord.lengthSq > 0: {
					m.worthExplorable.filter[
						val ot = times.get(origin)
						(ot == null || ot < originTime)
						//&& (s == null || s != p.key.id)
						// if we are origin, either we still see it
						// or it is an old explorable that should be forgotten
						&& !hasOrigin(requires.perceptions.myId)
						// if we are sender, then either we will see it
						// or receive it again, or it is an old one
						&& !hasSender(requires.perceptions.myId)
					]
				}
				default: List.nil
			}
		]
		
		// I update this info only with the new messages
		for(e: expl.map[value].flatten) {
			times.put(e.origin, e.originTime)
		}
		
		val toRemove = newHashSet() => [s|
			s += expl.map[key.id]
			logger.info("got new messages from {}", s)
		]
		
		val toKeep = newHashSet() => [s|
			s += requires.perceptions.visibleRobots.map[id]
		]
		
		pastMessages = pastMessages.filter[m|
			!toRemove.contains(m.key.id) && toKeep.contains(m.key.id) 
		] + expl.filter[!value.empty]
		
		pastMessages
	}
	
	override explorableWithSender(Explorable e) {
		e.withSender(requires.perceptions.myId, timestamp)
	}
	
	override newSeenExplorable(Double2D coord, double criticality) {
		new Explorable(coord, criticality, 0, requires.perceptions.myId, timestamp)
	}
	
}