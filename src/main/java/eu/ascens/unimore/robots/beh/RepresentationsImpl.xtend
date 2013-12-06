package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.Ord
import fj.P
import fj.P2
import fj.data.List
import org.slf4j.LoggerFactory
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*

class RepresentationsImpl extends Representations implements IRepresentationsExtra {
	
	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_preStep() {
		[|preStep]
	}
	
	override protected make_representations() {
		this
	}
	
	@Step
	def preStep() {
	}
	
	@StepCached
	override explorableVictims() {
		requires.perceptions.visibleVictims
			.map[buildVictim]
			=> [
				logger.info("explorableVictims: {}", it)
			]
	}
	
	@StepCached
	override responsibleVictims() {
		explorableVictims
			.filter[v|
				// do not consider it if there is another robot closer
				val distToV = v.coord.lengthSq
				requires.perceptions.visibleRobots.forall[b|
					val d = b.coord.distanceSq(v.coord)
					d > distToV
					// in case the distance is the same…
					|| (d == distToV && requires.perceptions.myId > b.id)
				]
			] => [
				logger.info("responsibleVictims: {}", it)
			]
	}
	
	
	@StepCached
	override explorableSeen() {
		// only keep those where there is no wall
		requires.perceptions.visibleFreeAreas
			.map[dir.buildSeen]
			=> [
				logger.info("explorableSeen: {}", it)
			]
	}
	
	@StepCached
	override responsibleSeen() {
		// consider only those from explorationMessages because if not
		// we have hole of vision when we didn't get some messages
		// but we want the info from their actual position so uses data from conesCoveredByVisibleRobots
		val eM = requires.messaging.explorationMessages
		val cones = requires.perceptions.visionConesCoveredByVisibleRobots.filter[p|eM.exists[key.id == p.key]]
		explorableSeen
			.filter[
				// it is visible only from me
				// i.e. this direction is not covered by others
				!cones.exists[c|coord.between(c.value)]
			]
			 => [
				logger.info("responsibleSeen: {}", it)
			]
	}
	
	@StepCached
	override explorableFromOthers() {
		requires.messaging.explorationMessages
			.map[p|
				p.value.map[e|
					val r = e.translatedVia(p.key)
					if (requires.perceptions.visibleWalls
						.exists[w|r.coord.between(w.cone)]
					) e.via(p.key)
					else r
				].maxEquivalentCriticalities
				.chooseBetweenEquivalentDirections
			]
			.keepOnePerOrigin
			=> [
				logger.info("explorableFromOthers: {}", it)
			]
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
	@StepCached
	override explorables() {
		
		(responsibleSeen
			+ responsibleVictims
			+ explorableFromOthers
		) => [
				logger.info("explorable: {}", it)
			]
	}
	
	def buildSeen(Double2D coord) {
		// reduce criticality of visible place where I come from?
		// TODO maybe smooth it a little?
		// we need something more intelligent here...
		requires.messaging.newSeenExplorable(
			coord,
//			if (requires.perceptions.goingBack(coord))
//				Constants.STARTING_EXPLORABLE_CRITICALITY/2.0
//			else
				Constants.STARTING_EXPLORABLE_CRITICALITY
		)
	}
	
	def buildVictim(Double2D coord) {
		// TODO reduce if there is a lot of people around?
		requires.messaging.newSeenExplorable(
			coord,
			Constants.STARTING_VICTIM_CRITICALITY
		)
	}
}