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
				val choice = explorables
								.maxEquivalentCriticalities
								.chooseBetweenEquivalentDirections
				
				// act
				handleGoTo(choice)
				handleSend(choice)
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
						|| (!to.sawMyself && to.distance < Constants.STOP_NEXT_TO_VICTIM_DISTANCE): {
				// in that case do nothing, no need to go crazily around
				// but stop closer if you are the one that saw it
			}
			default: requires.actions.goTo(to.direction)
		}
	}
	
	private def handleSend(Explorable to) {
		val toSend = switch to {
			Victim case to.distance > Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE: {
				// I'm going there but I'm not counted in the howMuch yet
				to.withHowMuch(to.howMuch-1)
			}
			default: to
		}
		
		requires.actions.broadcastExplorables(List.single(toSend))
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