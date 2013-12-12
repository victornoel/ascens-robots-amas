package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.AgentSig
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IMessagingExtra
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import java.util.Map
import java.util.Set

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class MessagingImpl extends Messaging implements IMessagingExtra {

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
	
	var Set<Explorable> previousTurn = newHashSet
	val Map<String, Integer> times = newHashMap
	
	@StepCached(forceEnable=true)
	override explorationMessages() {
		val msgs = requires.perceptions.visibleRobots.map[
			it -> switch message {
				case message.isSome && coord.lengthSq > 0: {
					val m = message.some
					switch m {
						ExplorableMessage: m.worthExplorable
						default: List.nil
					}
				}
				default: List.nil
			}
		]
		
		val allCurrentMsgs = msgs.map[value].flatten
		
		val res = msgs.map[
			key -> value.filter[
				// if we are origin, either we still see it
				// or it is an old explorable that should be forgotten
				!hasOrigin(requires.perceptions.myId)
				// if we are sender, then either we will see it
				// or receive it again, or it is an old one
				&& !hasSender(requires.perceptions.myId)
				&& (previousTurn.contains(it) || origin.time > times.getOr(origin.id, 0))
				&& !allCurrentMsgs.exists[m|m.origin.id == origin.id && m.origin.time>origin.time]
			]
		]
		
		val currentMsgs = res.map[value].flatten
		// seen times
		for(e: currentMsgs) {
			times.put(e.origin.id, e.origin.time)
		}
		
		previousTurn = currentMsgs.toSet
		
		res
	}
	
	override currentSig() {
		new AgentSig(requires.perceptions.myId, timestamp)
	}
	
}