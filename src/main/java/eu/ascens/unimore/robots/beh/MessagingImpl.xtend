package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.AgentSig
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.interfaces.IMessagingExtra
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import fj.data.Option
import java.util.Map

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.JavaExtensions.*

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
	
	val Map<String, Integer> times = newHashMap
	var Map<String, Integer> previousTimes = newHashMap
	
	@StepCached(forceEnable=true)
	override explorationMessages() {
		val msgs = requires.perceptions.visibleRobots.map[
			new RBEmitter(coord, id, Option.none) -> switch message {
				case message.isSome && coord.lengthSq > 0: {
					val m = message.some()
					switch m {
						ExplorableMessage: m.worthExplorable
						default: List.nil
					}
				}
				default: List.nil
			}
		].filter[value.notEmpty]
		
		val currentTimes = newHashMap
		val currentDistances = newHashMap
		
		for(m: msgs) {
			val from = m.key.id
			for (e: m.value) {
				val t = currentTimes.getOr(e.origin.id, 0)
				if (e.origin.time > t) {
					currentTimes.put(e.origin.id, e.origin.time)
					currentDistances.put(e.origin.id, from -> e.distance)
				} else if (e.origin.time == t) {
					val d = currentDistances.getOr(e.origin.id, "" -> Double.POSITIVE_INFINITY)
					if (e.distance < d.value) {
						currentDistances.put(e.origin.id, from -> e.distance)
					} else if (e.distance == d.value) {
						if (from < d.key) {
							currentDistances.put(e.origin.id, from -> e.distance)
						}
					}
				}
			}
		}
		
		// TODO shouldn't howMuch be merged?
		
		val res = msgs.map[
			val from = key.id
			key -> value.filter[
				// if we are origin, either we still see it
				// or it is an old explorable that should be forgotten
				!hasOrigin(requires.perceptions.myId)
				// if we were the previous sender, then either we will see it
				// or receive it again, or it is an old one
				&& !hasSender(requires.perceptions.myId)
				// check against other current messages
				&& {
					origin.time >= currentTimes.getSafe(origin.id)
				}
				// for new message also check against times stored
				&& {
					val prev = previousTimes.getOr(origin.id, 0)
					val curr = currentTimes.getSafe(origin.id)
					if (prev < curr) {
						// it's a new message, check against old times
						// to avoid looping messages
						origin.time > times.getOr(origin.id, 0)
					} else if (prev == curr) {
						// it's an old message, it is for sure of the same time as before
						// no need to check
						doAssert(origin.time == times.getOr(origin.id, 0), "")
						true
					} else {
						false
					}
				}
				// and only keep the best distance
				&& {
					val d = currentDistances.getSafe(origin.id)
					if (distance < d.value) true
					else if (distance == d.value && from <= d.key) true
					else false
				}
			]
		].filter[value.notEmpty]
		
		doAssert({
			val es = res.map[value].flatten
			es.forall[e1|!es.exists[e2|e2 !== e1 && e2.origin.id == e1.origin.id]]
		}, "")
		
		// seen times
		times.putAll(currentTimes)
		previousTimes = currentTimes
		
		res
	}
	
	override currentSig() {
		new AgentSig(requires.perceptions.myId, timestamp)
	}
	
}