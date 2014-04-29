package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import eu.ascens.unimore.robots.mason.datatypes.Choice
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.robots.common.VictimVision.*
import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.beh.datatypes.ExplorableFromVictim

class DecisionsImpl extends Decisions implements IDecisionsExtra {

	//val logger = LoggerFactory.getLogger("agent")
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_decisions() {
		this
	}
	
	var Choice lastChoice = [|new Double2D(0,0)]
	override lastChoice() {
		lastChoice
	}
	
	@StepCached
	private def void step() {
		
		val explorables = requires.representations.explorables
		val victimsOfInterest =	requires.representations.consideredVictims
		
		val selectedExplorable = if (explorables.notEmpty) {
			// decide
			val maxEquivalentExplorables = explorables.keepMaxEquivalents
			maxEquivalentExplorables.chooseBetweenEquivalentDirections
		} else {
			null
		}

		val choice = if (victimsOfInterest.empty) {
			selectedExplorable
		} else {
			// note: this could be inferred by the selectedExplorable normally…
			// but even if for us it means to go there, maybe we should not advertise
			// for it and advertise for the next best! (i.e. selectedExplorable?)
			// but what for us is the most critical, can be (if we are the last one missing)
			// less critical for another one… if we send, for example, 2 explorable
			// when he looks at it, maybe he will realise that by himself…
			victimsOfInterest.mostInNeedVictim
		}

		// TODO we need to slow down to wait for others to keep them advertised
		// or we need to keep some memory of previous choices in case
		// we loose contact
		if (choice != null) {
			requires.actions.goTo(choice.direction)
			lastChoice = choice
		} else {
			lastChoice = [|new Double2D(0,0)]
		}
		
		if (selectedExplorable != null) {
			// on victim means that the choice I advertise is not where I am going...
			val onVictim = choice instanceof SeenVictim
							&& ((choice as SeenVictim).imNext
								|| (selectedExplorable instanceof ExplorableFromVictim
									&& (selectedExplorable as ExplorableFromVictim).relatedVictim === choice))
			requires.actions.broadcastExplorables(List.single(selectedExplorable), onVictim)
		}
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		in
			.map[e|P.p(e, e.distanceToLast)]
			.maximum(Ord.doubleOrd.comap(P2.__2))
			._1
			//.index(requires.random.pull.nextInt(in.length))
	}
	
	// the bigger the closer to the previous direction
	private def distanceToLast(Explorable e) {
		e.direction.dot(lastChoice.direction)
	}
}