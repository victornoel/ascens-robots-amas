package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import eu.ascens.unimore.xtend.macros.Step
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

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
		
		val choice = chooseWhereToGo
		
		if (choice == null) {
			logger.info("nowhere to go")
		} else {
			requires.actions.goTo(choice)
			// we send all of them and not only the most critical
			// because ... why?
			requires.actions.broadcastExplorables(requires.representations.explorables)
		}
	}
	
	private def chooseWhereToGo() {
		val explorables = requires.representations.explorables
		if (explorables.empty) null
		else explorables
				.keepEquivalentDirections
				.chooseBetweenEquivalentDirections
	}
	
	private def keepEquivalentDirections(List<Explorable> in) {
		in.maxEquivalentCriticalities
			=> [
				logger.info("kept: {}.", it)
			]
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		in.map[e|P.p(e,e.distanceToCrowd)]
			// use maximum in case they are all equal!
			//.maximum(crowdOrd.comap(P2.__2))
			.maximums(crowdEq.comap(P2.__2), crowdOrd.comap(P2.__2))
			.map[P.p(_1, _1.distanceToLast)]
			.maximum(Ord.doubleOrd.comap(P2.__2))
			._1
			.coord
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