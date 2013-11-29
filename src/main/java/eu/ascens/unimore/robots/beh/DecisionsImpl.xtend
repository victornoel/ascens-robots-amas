package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IDecisionsExtra
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import fj.Function
import fj.Ord
import fj.Ordering
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair
import org.slf4j.LoggerFactory
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.Utils.*

class DecisionsImpl extends Decisions implements IDecisionsExtra {

	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_decisions() {
		this
	}
	
	override lastChoice() {
		lastChoice
	}
	
	var lastChoice = RelativeCoordinates.of(new Double2D(0,0))
	
	private def void step() {
		
		val choice = chooseWhereToGo
		
		if (choice == null) {
			logger.info("nowhere to go")
		} else {
			requires.actions.goTo(choice)
			requires.actions.broadcastExplorables(requires.representations.explorables.map[clean])
			lastChoice = choice
		}
		
		// choisir une direction où aller
		// il faut savoir où se trouve
		// - des victimes
		// - des endroits à explorer
		// - la maison 
	}
	
	private def chooseWhereToGo() {
		val explorables = requires.representations.explorables
		if (explorables.empty) null
		else explorables
				.keepEquivalentDirections
				.chooseBetweenEquivalentDirections
				//.correctChoiceInCaseOfMisPerceptions
	}
	
//	var count = 0
//	private def correctChoiceInCaseOfMisPerceptions(RelativeCoordinates choice) {
//		// vectors going in opposite directions: stay on the course for 3 turns
//		if (actions.lastChoice != null && choice != null && choice.value.dot(actions.lastChoice.value) < 0 && count < 6) {
//			count = count +1
//			logger.info("going back, in case it is an error, staying on course (count={})", count)
//			actions.lastChoice
//		} else {
//			count = 0
//			choice
//		}
//	}
	
	private def keepEquivalentDirections(List<Explorable> in) {
		
		// use inverse to sort with max first
		val kept = in.keepEquivalentFirsts(explorableCriticalityOrd.equal, strictExplorableCriticalityOrd.inverse)
		
		logger.info("kept: {}.", kept)
		
		kept
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
		
		val withDotLastChoice = in.map[e|
			// the higher, the closer to the previous direction
			e -> lastChoice.value.dot(e.coord.value)
		]
		
		var withoutBack = withDotLastChoice.filter[value > 0]
		
		logger.info("without back: {}", withoutBack)
		
		val toUse = if (withoutBack.empty) withDotLastChoice else withoutBack
		
		val withNbBotsBehind = toUse.map[
			val e = key
			val dot = value
			e -> dot -> requires.perceptions.visibleRobots.count[b|
								// keep robots in the opposite direction:
								// we want to go away from them
								b.coord.value.dot(e.coord.value) < 0
							]
		]
		
		withNbBotsBehind.maximum(Ord.ord(Function.curry(
			[Pair<Pair<Explorable, Double>, Integer> a, Pair<Pair<Explorable, Double>, Integer> b|
				
				val explA = a.key.key
				val explB = b.key.key
				
				val dotA = a.key.value
				val nbBotsBehindA = a.value
				
				val dotB = b.key.value
				val nbBotsBehindB = b.value
				
				// we want the shortest thus we inverse the result
				val distO = Ord.doubleOrd.compare(explB.distance, explA.distance)
				if (distO == Ordering.EQ) {
					// we want the biggest
					val nbBotsO = Ord.intOrd.compare(nbBotsBehindA, nbBotsBehindB)
					if (nbBotsO == Ordering.EQ) {
						// we want the 
						Ord.doubleOrd.compare(dotA, dotB)
					} else nbBotsO
				} else distO
			]
		))).key.key.coord
	}
	
	
	
}