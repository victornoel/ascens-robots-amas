package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.Victim
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import eu.ascens.unimore.xtend.macros.StepCached
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
	
	// this should not be used to take a decision!
	var Explorable lastChoice
	override lastChoice() {
		lastChoice
	}
	
	@StepCached
	private def void step() {
		
		val explorables = requires.representations.explorables
		// perceive
		switch explorables {
			case List.nil: {
				logger.info("nowhere to go")
			}
			default: {
				// decide
				val sortedExplorables = explorables.orderByDescendingCriticality
				
				val equivalentExplorables = sortedExplorables
												.keepEquivalent
				
				val choice = if (Constants.COOPERATION || Constants.COOPERATION1)
								equivalentExplorables.chooseBetweenEquivalentDirections
								else equivalentExplorables.chooseBetweenEquivalentDirectionsRandom
				
				// act
				// TODO maybe we should advertise on the other interesting thing
				// if the choice is about a victim that we are close to with enough people
				handleGoTo(choice)
				if (Constants.COOPERATION) {
					handleSend(choice, sortedExplorables)
				}
				// this should not be used by decision!
				lastChoice = choice
			}
		}
	}
	
	// TODO we need to slow down to wait for others to keep them advertised
	// or we need to keep some memory of previous choices in case
	// we loose contact
	private def handleGoTo(Explorable to) {
		switch to {
			Victim case (to.sawMyself && to.distance < Constants.STOP_AS_RESP_NEXT_TO_VICTIM_DISTANCE)
						|| (!to.sawMyself && to.direction.length < Constants.STOP_NEXT_TO_VICTIM_DISTANCE): {
				// in that case do nothing, no need to go crazily around
				// but stop closer if you are the one that saw it
			}
			default: requires.actions.goTo(to.direction)
		}
	}
	
	private def handleSend(Explorable to, List<Explorable> sortedExplorables) {
		val toSend = switch to {
			Victim case to.distance > Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE: {
				// I'm going there but I'm not counted in the howMuch yet
				to.withHowMuch(to.howMuch+1)
			}
			default: to
		}
		
		val others = List.nil //sortedExplorables.filter[to !== it].keepEquivalent
		
		requires.actions.broadcastExplorables(toSend + others)
	}
	
	private def chooseBetweenEquivalentDirectionsRandom(List<Explorable> in) {
		val i = requires.random.pull.nextInt(in.length)
		in.index(i)
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		in
			.map[e|P.p(e,e.distanceToCrowd)]
			.maximums(crowdEq.comap(P2.__2), crowdOrd.comap(P2.__2))
			.map[_1]
			.map[e|P.p(e, e.distanceToLast)]
			.maximum(Ord.doubleOrd.comap(P2.__2))
			._1
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