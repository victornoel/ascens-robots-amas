package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
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
	
	@Step
	private def void step() {
		val explorables = requires.representations.explorables
		
		switch explorables {
			case List.nil: {
				logger.info("nowhere to go")
			}
			default: {
				
				// normalize them over the 36 directions
//				val explo = SENSORS_DIRECTIONS_CONES
//					.map[p|explorables.filter[direction.between(p.value)]]
//					.filter[notEmpty]
//					.map[
//						maxEquivalentCriticalities
//						.chooseBetweenEquivalentDirections
//					]
				
				val choice = explorables
								.maxEquivalentCriticalities
								//.keepOnePerOrigin
								.chooseBetweenEquivalentDirections
				
				requires.actions.goTo(choice.direction)
				requires.actions.broadcastExplorables(List.single(choice))
				
				lastChoice = choice
			}
		}
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		in
			//.minimums(Equal.intEqual.comap[Explorable it|howMuch], Ord.intOrd.comap[Explorable it|howMuch])
			.map[e|P.p(e,e.distanceToCrowd)]
			// use maximum in case they are all equal!
			//.maximum(crowdOrd.comap(P2.__2))
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