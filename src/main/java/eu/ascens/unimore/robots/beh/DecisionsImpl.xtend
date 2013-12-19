package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.Victim
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import eu.ascens.unimore.xtend.macros.Step
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class DecisionsImpl extends Decisions implements IDecisionsExtra {

	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_decisions() {
		this
	}
	
	var Explorable lastChoice
	
	override lastChoice() {
		lastChoice
	}
	
	private def removeUninterestingVictims(List<Explorable> es) {
		es.filter[e|
			switch e {
				Victim: {
					// TODO not really correct, more than the desired number could be
					// getting closer then…
					// maybe consider how much bots are closer than me?
					e.sawMyself
					|| e.distance < Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE
					|| e.howMuch > 0
				}
				default: true
			}
		]
	}
	
	@Step
	private def void step() {
		val explorables = requires.representations.explorables
		
		switch explorables {
			case List.nil: {
				logger.info("nowhere to go")
			}
			default: {
				
				val eqEs = explorables.maxEquivalentCriticalities
				val eqEsWoutHM = eqEs.removeUninterestingVictims
				
				val toUse = if (eqEsWoutHM.notEmpty) eqEsWoutHM else {
					val expWoutHM = explorables.removeUninterestingVictims
					if (expWoutHM.notEmpty) expWoutHM.maxEquivalentCriticalities
					else eqEs
				}
				val choice = toUse.chooseBetweenEquivalentDirections
				
				switch choice {
					Victim case (choice.sawMyself && choice.distance < Constants.STOP_AS_RESP_NEXT_TO_VICTIM_DISTANCE)
								|| (!choice.sawMyself && choice.distance < Constants.STOP_NEXT_TO_VICTIM_DISTANCE): {
						// but stop closer if you are the one that saw it
						// in that case do nothing, no need to go crazily around
					}
					default: requires.actions.goTo(choice.direction)
				}
				
				val toSend = switch choice {
					Victim: choice.minusOne
					default: choice
				}
				
				requires.actions.broadcastExplorables(List.single(toSend))
				
				lastChoice = choice
			}
		}
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		
//		val onlyFromMe = in.filter[sawMyself]
//		
//		if (onlyFromMe.notEmpty) {
//			// unless it's because I just lost contact...
//			onlyFromMe
//				.map[e|P.p(e,e.distanceToCrowd)]
//				.maximums(crowdEq.comap(P2.__2), crowdOrd.comap(P2.__2))
//				.map[_1]
//				.map[e|P.p(e, e.distanceToLast)]
//				.maximum(Ord.doubleOrd.comap(P2.__2))
//				._1
//		} else {
//			val fromPreviousOrigin = if (lastChoice != null) {
//				in.filter[origin.id == lastChoice.origin.id]
//			} else List.nil
//			
//			if (fromPreviousOrigin.notEmpty) {
//				doAssert(fromPreviousOrigin.size == 1, fromPreviousOrigin.toString)
//				fromPreviousOrigin.head
//			} else {
				in
					//.minimums(Equal.intEqual.comap[Explorable it|howMuch], Ord.intOrd.comap[Explorable it|howMuch])
					.map[e|P.p(e,e.distanceToCrowd)]
					// use maximum in case they are all equal!
//					.maximum(crowdOrd.comap(P2.__2))
					.maximums(crowdEq.comap(P2.__2), crowdOrd.comap(P2.__2))
					.map[_1]
					.map[e|P.p(e, e.distanceToLast)]
					.maximum(Ord.doubleOrd.comap(P2.__2))
					._1
//			}
//		}
	}
	
	// the bigger the closer to the previous direction
	private def distanceToLast(Explorable e) {
		e.direction.dot(requires.perceptions.previousDirection)
	}
	
	// the bigger, the closer to the farthest from the crowd
	private def distanceToCrowd(Explorable e) {
		e.direction.dot(requires.perceptions.escapeCrowdVector)
	}
}