package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.geometry.RelativeCoordinates
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

class RepresentationsImpl extends Representations implements IRepresentationsExtra {
	
	val logger = LoggerFactory.getLogger("agent")
	
	override protected make_preStep() {
		[|preStep]
	}
	
	override protected make_representations() {
		this
	}
	
	var int timestamp = 0
	
	@Step
	def preStep() {
		timestamp = timestamp+1
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
		requires.perceptions.sensorReadings
			// it is not a wall
			.filter[!value]
			.map[key.buildSeen]
			=> [
				logger.info("explorableSeen: {}", it)
			]
	}
	
	@StepCached
	override responsibleSeen() {
		// consider only those from explorationMessages because if not
		// we have hole of vision when we didn't get some messages
		// but we want the info from their actual position so uses data from conesCoveredByVisibleRobots
		val eM = requires.perceptions.explorationMessages
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
		requires.perceptions.explorationMessages
			.map[p|p.value.map[e|
					val r = e.translatedVia(p.key)
					if (requires.perceptions.visibleWalls
						.exists[w|r.coord.between(w)]
					) e.via(p.key)
					else r
				]
			].flatten
			.keepOnePerOrigin
			=> [
				logger.info("explorableFromOthers: {}", it)
			]
		/*
		 * we did:
		 * 1) remove things from me
		 * 3) keep only one per origin/maxcrit for all based on distance
		 * => we have one per origin, different crits
		 */
	}
	
	@StepCached
	override explorables() {
		
		val explo = (
			responsibleSeen
			+ responsibleVictims
			+ explorableFromOthers.downcast
		)
		
		// normalize them over the 24 directions
//		RelativeCoordinates.SENSORS_DIRECTIONS_CONES
//			.map[p|explo.filter[coord.value.between(p.cone)]]
//			.filter[!empty]
//			.map[
//				maximum(explorableCriticalityOrd)
//			]
//			=> [
//				logger.info("explorable: {}", it)
//			]
			explo => [
				logger.info("explorable: {}", it)
			]
	}
	
	def buildSeen(RelativeCoordinates coord) {
		// reduce criticality of visible place where I come from?
		// TODO maybe smooth it a little?
		new Explorable(
			coord,
			if (requires.perceptions.goingBack(coord))
				Constants.STARTING_EXPLORABLE_CRITICALITY/2.0
			else
			// we nee dsomething more intelligent here...
				Constants.STARTING_EXPLORABLE_CRITICALITY,
			0,
			requires.perceptions.myId,
			timestamp
		)
	}
	
	def buildVictim(RelativeCoordinates coord) {
		// TODO reduce if there is a lot of people around?
		new Explorable(
			coord,
			Constants.STARTING_VICTIM_CRITICALITY,
			0,
			requires.perceptions.myId,
			timestamp
		)
	}
}