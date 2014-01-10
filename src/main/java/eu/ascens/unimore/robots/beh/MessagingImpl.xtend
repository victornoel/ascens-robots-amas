package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.AgentSig
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.datatypes.ReceivedExplorable
import eu.ascens.unimore.robots.beh.interfaces.IMessagingExtra
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
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
		
		// TODO is all of this really useful? If disabled it still works...
		// most certainly because of the howmuch information...!!
		// but only for victims!
		// if we say that distance is still used, but not the timestamp
		// that could be alright? -> no because it wouldn't prevent
		// msg to be ignored when looping between agents when nothing new is coming from the
		// origin -> or we need to remember distance? beurk
		
		val msgs = requires.perceptions.visibleRobots.map[vb|
			switch vb.message {
				case vb.message.isSome && vb.coord.lengthSq > 0: {
					switch m: vb.message.some(){
						ExplorableMessage: m.worthExplorable.map[
							new ReceivedExplorable(vb.id, vb.coord, it, 1)
						]
						default: List.nil
					}
				}
				default: List.nil
			}
		].flatten
		.filter[
			// if we are origin, either we still see it
			// or it is an old explorable that should be forgotten
			!explorable.hasOrigin(requires.perceptions.myId)
			// if we were the previous sender, then either we will see it
			// or receive it again, or it is an old one
			&& !explorable.hasSender(requires.perceptions.myId)
		]
		
		val bestTimesByOrigin = newHashMap
		val bestReceivedExplorableByOrigin = newHashMap
		
		for(it: msgs) {
			val originId = explorable.origin.id
			val bT = bestTimesByOrigin.getOr(originId, Integer.MIN_VALUE)
			
			if (explorable.origin.time > bT) {
				bestTimesByOrigin.put(originId, explorable.origin.time)
				bestReceivedExplorableByOrigin.put(originId, it)
			} else if (explorable.origin.time == bT) {
				val bE = bestReceivedExplorableByOrigin.getSafe(originId)
				if (explorable.distance < bE.explorable.distance
					|| (explorable.distance == bE.explorable.distance && fromId < bE.fromId)) {
					bestReceivedExplorableByOrigin.put(originId, it.withHowManyMore(bE.fromHowMany))
				}
			}
		}
		
		val res = List.iterableList(bestReceivedExplorableByOrigin.values).filter[
			val prev = previousTimes.getOr(explorable.origin.id, 0)
			if (prev < explorable.origin.time) {
				// it's a new message, check against old times
				// to avoid looping messages
				explorable.origin.time > times.getOr(explorable.origin.id, 0)
			} else if (prev == explorable.origin.time) {
				// it's an old message, it is for sure of the same time as before
				// no need to check
				doAssert(explorable.origin.time == times.getOr(explorable.origin.id, 0), "")
				true
			} else {
				false
			}
		]
		
		doAssert({
			res.forall[e1|!res.exists[e2|e2 !== e1 && e2.explorable.origin.id == e1.explorable.origin.id]]
		}, "")
		
		// seen times
		times.putAll(bestTimesByOrigin)
		previousTimes = bestTimesByOrigin
		
		res
	}
	
	override currentSig() {
		new AgentSig(requires.perceptions.myId, timestamp)
	}
	
}