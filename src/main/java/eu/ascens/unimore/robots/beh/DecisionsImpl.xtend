package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Choice
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

class DecisionsImpl extends Decisions implements IDecisionsExtra {

	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_decisions() {
		this
	}
	
	// this should not be used to take a decision!
	var Choice lastChoice
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
				val maxEquivalentExplorables = explorables.keepMaxEquivalent
				val selectedExplorable = maxEquivalentExplorables.chooseBetweenEquivalentDirections
				
				val victimsOfInterest =	requires.representations.consideredVictims
				
				// TODO we need to slow down to wait for others to keep them advertised
				// or we need to keep some memory of previous choices in case
				// we loose contact
				val choice = if (victimsOfInterest.empty) {
					selectedExplorable
				} else {
					// note: this could be inferred by the selectedExplorable normally…
					// but even if for us it means to go there, maybe we should not advertise
					// for it and advertise for the next best! (i.e. selectedExplorable?)
					// but what for us is the most critical, can be (if we are the last one missing)
					// less critical for another one… if we send, for example, 2 explorable
					// when he looks at it, maybe he will realise that by himself…
					victimsOfInterest.mostImportantVictim
				}
				
				handleGoto(choice)
				handleSend(selectedExplorable, choice !== selectedExplorable)
				// this should not be used by decision!
				lastChoice = choice
			}
		}
	}
	
	def handleGoto(Choice choice) {
		requires.actions.goTo(choice.direction)
	}
	
	private def handleSend(Explorable to, boolean onVictim) {
		requires.actions.broadcastExplorables(List.single(to), onVictim)
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