package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import eu.ascens.unimore.xtend.macros.Step
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import org.slf4j.LoggerFactory

import static eu.ascens.unimore.robots.geometry.GeometryExtensions.*

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

class DecisionsImpl extends Decisions implements IDecisionsExtra {

	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_decisions() {
		this
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
				val explo = SENSORS_DIRECTIONS_CONES
					.map[p|explorables.filter[coord.between(p.value)]]
					.filter[notEmpty]
					.map[
						maxEquivalentCriticalities.chooseBetweenEquivalentDirections
					]
				
				val choice = explo.maxEquivalentCriticalities.chooseBetweenEquivalentDirections
				
				requires.actions.goTo(choice.coord)
				// we send all of them and not only the most critical
				// because ... why?
				requires.actions.broadcastExplorables(explo)
			}
		}
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		in
			.map[e|P.p(e,e.distanceToCrowd)]
			// use maximum in case they are all equal!
//			.maximum(crowdOrd.comap(P2.__2))
			.maximums(crowdEq.comap(P2.__2), crowdOrd.comap(P2.__2))
			.map[_1]
			.map[e|P.p(e, e.distanceToLast)]
			.maximum(Ord.doubleOrd.comap(P2.__2))
			._1
	}
	
	// the bigger the closer to the previous direction
	private def distanceToLast(Explorable e) {
		requires.perceptions.previousDirection.dot(e.coord)
	}
	
	// the bigger, the closer to the farthest from the crowd
	private def distanceToCrowd(Explorable e) {
		e.coord.dot(requires.perceptions.escapeCrowdVector)
	}
}