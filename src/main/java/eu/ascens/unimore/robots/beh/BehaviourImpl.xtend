package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.Function
import fj.Ord
import fj.Ordering
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.Utils.*

/*
 * Note
 * 
 * 1) si la finalité est de faire des chaines, il ne feront pas mieux que ça, et certainement pire
 *  -> pas de finalité (où finalité très qualitative) et émergence : des chaines emergent, mais peuvent faire mieux dans situations extremes
 * 2) difficile à faire car
 *  a) émergence doit faire quelque chose de bien ! commet ? cooperation principalement...
 *  b) le concepteur ne pourra jamais se débarasser d'une finalité ou d'un désir de voir apparaitre des trucs prévus
 * 3) les capacités d'interaction de base (i.e. la définition du pb) aura un impact extremement important sur comment approcher le problème
 *  -> si agent peut voir chemins et reconnaitre salle, l'approche sera de choisir le bon chemin entre des salles, alors que si voit que mur ou pas mur, l'approche sera plus bas niveau
 *  -> lorsque l'on experimente en tant que chercheur, ça pose problème !!!
 * 
 */
 
 /*
  * problems:
  * 
  * 1) dès que y en a un qui voit une victime ils crient tous : moi moi moi je le vois
  * et tout le monde se court après et forment une ronde :D
  * 
  * 2) quand ils se séparent, si ya 2 stream d'agents un peu opposé, ils se renforcent
  * parce qu'ils vont que dans la direction inverse du plus...
  * 
  * prez:

milestones (fonctionalités : explorer, trouver, appeler les autres, retrouver maison et ramener)
et pour chaque problèmes (non-fonctionnel : explorer en se séparant, trouver et ne pas s'aglutiner, retrouver maison de façon efficace, etc)

détailler un peu plus les milestones et expliquer qu'on avance le dev jusqu'à en atteindre une et on se concentre sur les problèmes, puis on ocntinue-

On documente la solution du problème, on en tire des conclusions
  * 
  */
//@DisableStepCached
class BehaviourImpl extends Behaviour {
	
	package val logger = LoggerFactory.getLogger("agent")
	
	override protected make_visu() {
		visu
	}
	
	package val extension Perceptions perceptions = new Perceptions(this)
	package val extension Actions actions = new Actions(this)
	package val extension Decisions decisions = new Decisions(this)
	package val extension ExplorablesRepresentations explorables = new ExplorablesRepresentations(this)
	
	val Visu visu = new Visu(this)
	
	@StepCached(forceEnable=true)
	def myId() {
		requires.id.pull
	}
	
	@Step
	def void step() {
		
		perceptions.preStep
		decisions.preStep
		explorables.preStep
		
		logger.info("\n\n-----------------------")
		logger.info("lastChoice: {}", lastChoice)
		
		// perceive
		
		// decide

		val choice = chooseWhereToGo
		
		if (choice == null) {
			logger.info("nowhere to go")
		} else {
			goTo(choice)
			
			requires.rbBroadcast.push(new ExplorableMessage(explorableToCommunicate, conesCoveredByVisibleRobots.toMap))
		}
		
		// choisir une direction où aller
		// il faut savoir où se trouve
		// - des victimes
		// - des endroits à explorer
		// - la maison 
		

	}
	
	override protected make_step() {[|step]}
	
	def _requires() { requires }
	
}

class ExplorablesRepresentations {
	
	val extension BehaviourImpl beh
	
	new(BehaviourImpl beh) {
		this.beh = beh
	}
	
	@Step
	def preStep() {}
	
	@StepCached
	private def List<Explorable> explorableVictims() {
		val res = perceptions.visibleVictims
					.map[new VictimRepresentation(it) as Explorable]
		logger.info("explorableVictims: {}", res)
		res
	}
	
	@StepCached
	private def List<Explorable> explorableFromMe() {
		// only keep those where there is no wall
		val res = perceptions.sensorReadings
					.filter[!value]
					.map[new SeenExplorableRepresentation(key) as Explorable]
		logger.info("explorableFromMe: {}", res)
		res
	}
	
	@StepCached
	def List<Explorable> explorableOnlyFromMe() {
		// consider only those from explorationMessages because if not
		// we have hole of vision when we didn't get some messages
		// but we want the info from their actual position so uses data from conesCoveredByVisibleRobots
		val eM = perceptions.explorationMessages
		val cones = perceptions.conesCoveredByVisibleRobots.filter[p|eM.exists[it.key.id == p.key]]
		val res = explorableFromMe.filter[d|
			// it is explorable only from me
			// if this direction is not covered by others
			!cones.exists[c|d.coord.value.between(c.value.cone)]
		]
		logger.info("explorableOnlyFromMe: {}", res)
		res
	}

	@StepCached
	def List<Explorable> explorableFromOthers() {
		val res = perceptions.explorationMessages.map[p|
			// note: all of these vectors are consistent with the position
			// of the emitter when he sent them
			val hisPosFromMe = p.key.coord
			val mess = p.value
			// also contains the cone covered
			val myConeFromHim = mess.others.get(myId)
			/*
			// this exactly corresponds to what he computed when he sent his message
			val coveredConeFromHim = myPosFromHim.value.computeConeCoveredByBot(VISION_RANGE_SQUARED)
			val es = mess.worthExplorable
				// remove those in our direction
				// avoid getting back what we just sent him and also noise
				// because our vision is better in that direction
				// normally this should avoid mutiple version of the same information
				.filter[
					coveredConeFromHim == null || !coord.value.between(coveredConeFromHim.cone)
				]
				// translateFromHimToMe is not correct if the basis for both bot was different...
				.map[new Explorable(
						RelativeCoordinates.of(coord.value.translateFromAToB(hisPosFromMe.value, myPosFromHim.value).resize(Constants.VISION_RANGE)),
						botNeeded)
				].toList
			// remove those for which we actually see a wall
			val walled = es.filter[e|wallsFromMe.exists[w|e.coord.value.between(w.cone)]].toList
			es.removeAll(walled)
			// if we filtered some, it means there is more to be seen from the pov of the bot
			// this would be an approximation of the best way to go to that place
			val nb = walled.fold(0, [a,b|Math.max(a, b.botNeeded)])
			if (!walled.empty) es + #[new Explorable(hisPosFromMe, nb)]
			else es
			*/
//			if (hisPosFromMe.value.lengthSq < 1) {
//				null
//			} else {
				// only keep those not in the same direction as me from him
				// this avoid getting back what we sent him for example
				val e = if (myConeFromHim != null) mess.worthExplorable.filter[
					!coord.value.between(myConeFromHim.cone)
					//coord.value.dot(myPosFromHim.value) < 0
				] else mess.worthExplorable
				if (e.empty) {
					null
				} else {
					// here we just take the maximum, because criticality is not about the
					// number of people needed but just the importance of the direction
					e.maximum(strictExplorableCriticalityOrd).aggregates(hisPosFromMe, e)
				}
		].filter([it != null])
		logger.info("explorableFromOthers: {}", res)
		res
	}
	
	@StepCached
	def allExplorables() {
		
		val explo = (
			explorableOnlyFromMe
			.append(explorableFromOthers)
			.append(explorableVictims)
		)
		
		// normalize put all of it in 24 directions
		val res = RelativeCoordinates.SENSORS_DIRECTIONS_CONES.map[p|
			val candid = explo.filter[coord.value.between(p.cone)]
			if (candid.empty) null
			else {
				candid.maximum(strictExplorableCriticalityOrd)
			}
		].filter[it != null]
		
		logger.info("explorable: {}", res)
		res
	}
	
}

class Decisions {
	
	val extension BehaviourImpl beh
	
	new(BehaviourImpl beh) {
		this.beh = beh
	}
	
	@Step
	def preStep() {}
	
	@StepCached
	def explorableToCommunicate() {
		explorables.allExplorables.map[clean]
	}
	
	@StepCached
	def chooseWhereToGo() {
		if (explorables.allExplorables.empty) null
		else explorables.allExplorables
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
		
		// is it with reverse?
		val sorted = in.sort(strictExplorableCriticalityOrd).reverse
		
		logger.info("sorted by criticality: {}.", sorted)

		// keep the first ones
		// TODO uses takeWhile from fj instead?
		val firstValue = sorted.head
		val kept = sorted.takeWhile[explorableCriticalityOrd.eq(firstValue, it)]
		
		logger.info("kept (for value {}): {}.", firstValue.criticality, kept)
		
		kept
	}
	
	private def chooseBetweenEquivalentDirections(List<Explorable> in) {
			
		val withDotLastChoice = in.map[e|
			e -> if (actions.lastChoice != null) {
				actions.lastChoice.value.dot(e.coord.value)
			} else 0.0 // must be negative or zero!!
		]
		
		var withoutBack = withDotLastChoice.filter[value > 0]
		
		logger.info("without back: {}", withoutBack)
		
		val toUse = if (withoutBack.empty) withDotLastChoice else withoutBack
		
		val withNbBotsBehind = toUse.map[
			val e = key
			val dot = value
			e -> dot -> perceptions.visibleRobots.count[b|
								// keep robots in the opposite direction:
								// we want to go away from them
								b.coord.value.dot(e.coord.value) < 0
							]
		]
		
		withNbBotsBehind.maximum(Ord.ord(Function.curry(
			[Pair<Pair<Explorable, Double>, Integer> a, Pair<Pair<Explorable, Double>, Integer> b|
				val dotA = a.key.value
				val nbBotsBehindA = a.value
				
				val dotB = b.key.value
				val nbBotsBehindB = b.value
				
				val nbBotsO = Ord.intOrd.compare(nbBotsBehindA, nbBotsBehindB)
				
				if (nbBotsO == Ordering.EQ) Ord.doubleOrd.compare(dotA, dotB)
				else nbBotsO
			]
		))).key.key.coord
	}
	
}

class Visu implements RobotVisu {
	
	val extension BehaviourImpl beh
	
	new(BehaviourImpl beh) {
		this.beh = beh
	}
	
	override getLastChoice() {
		actions.lastChoice
	}
	
	override consideredExplorable() {
		explorables.allExplorables
	}
	
	override consideredExplorableOnlyFromMe() {
		explorables.explorableOnlyFromMe
	}
	
	override consideredExplorableFromOthers() {
		explorables.explorableFromOthers
	}
	
	override visibleBots() {
		perceptions.conesCoveredByVisibleRobots.map[value]
	}
}

class Actions {
	
	val extension BehaviourImpl beh
	
	new(BehaviourImpl beh) {
		this.beh = beh
	}
	
	var RelativeCoordinates lastChoice
	
	def getLastChoice() {
		lastChoice
	}
	
	def goTo(RelativeCoordinates to) {
		
		val move = to.computeDirectionWithAvoidance(perceptions.wallsFromMe)
		
		logger.info("going to {} targetting {}.", move, to)
		_requires.move.setNextMove(move)
		lastChoice = to
	}
	
}

class Perceptions {
	
	val extension BehaviourImpl beh
	
	new(BehaviourImpl beh) {
		this.beh = beh
	}
	
	@Step
	def preStep() {}
	
	@StepCached(forceEnable=true)
	def rbMessages() {
		val res = List.iterableList(_requires.RBMessages.pull)
		logger.debug("rbMessages: {}", res)
		res
	}
	
	@StepCached
	def wallsFromMe() {
		sensorReadings
			.filter[value]
			.map[key]
			.toList
	}

	@StepCached
	def sensorReadings() {
		val res = _requires.see.sensorReadings
		logger.info("sensorReadings: {}", res)
		res
	}
	
	@StepCached
	def visibleRobots() {
		val res = _requires.see.RBVisibleRobots
		logger.info("visibleRobots: {}", res)
		res
	}
	
	@StepCached
	def visibleVictims() {
		_requires.see.visibleVictims
	}
	
	static val VISION_RANGE_SQUARED = Constants.VISION_RANGE*Constants.VISION_RANGE
		
	@StepCached
	def conesCoveredByVisibleRobots() {
		// consider all visible bots
		visibleRobots.map[id -> coord.value.computeConeCoveredByBot(VISION_RANGE_SQUARED)]
	}
	
	@StepCached
	def explorationMessages() {
		// I should have only one message from each robot TODO check
		val res = rbMessages.filter[
			val m = it.message
			switch m {
				ExplorableMessage: true
				default: false
			}
		].map[
			emitter -> (message as ExplorableMessage)
		]
		
		if (logger.infoEnabled) {
			logger.info("got messages from {}", res.map[key.id])
		}
		
		res
	}
	
}
