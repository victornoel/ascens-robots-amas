package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import java.util.Map
import org.slf4j.LoggerFactory

import static extension eu.ascens.unimore.robots.Utils.*
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
				// do not take care of it if there is another robot closer
				val distToV = v.coord.value.lengthSq
				requires.perceptions.visibleRobots.forall[b|
					b.coord.value.distanceSq(v.coord.value) >= distToV
				]
			] => [
				logger.info("responsibleVictims: {}", it)
			]
	}
	
	
	@StepCached
	override explorableSeen() {
		// only keep those where there is no wall
		requires.perceptions.sensorReadings
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
		requires.perceptions.sensorReadings
			.filter[
				// it is not a wall
				!value
				// it is visible only from me
				// i.e. this direction is not covered by others
				&& !cones.exists[c|key.value.between(c.value.cone)]
			].map[key.buildSeen]
			 => [
				logger.info("responsibleSeen: {}", it)
			]
	}
	
	val Map<String, Integer> times = newHashMap
	val Map<String, String> senders = newHashMap
	
	@StepCached
	override explorableFromOthers() {
		requires.perceptions.explorationMessages
			.map[p|
				// note: this vector is consistent with the position
				// of the emitter when he sent them
				// and also contains the rb cone covered at the time
				val myConeFromHim = p.value.others.get(requires.perceptions.myId)
				// only keep those not in the same direction as me from him
				// this avoid getting back what we sent him for example
				// and without me as sender -> isn't that the same?
				// maybe not...
				p.value.worthExplorable
					.filter[
						val t = times.get(origin)
						//val s = senders.get(origin)
						
						(t == null || t <= originTime)
						//&& (s == null || s != p.key.id)
					].filter[
						// if we are origin, either we still see it
						// or it is an old explorable that should be forgotten
						!hasOrigin(requires.perceptions.myId)
						// if we are sender, then either we will see it
						// or receive it again, or it is an old one
						&& !hasSender(requires.perceptions.myId)
						// remove those coming from my side and didn't see by himself
						// in particular that must contain those sent from others
						// since mine are ignored by "sender"
						&& (myConeFromHim == null
							|| !coord.value.between(myConeFromHim.cone)
						)
					].map[via(p.key)]
			].flatten
			.keepOnePerOrigin
			.<Explorable>downcast
			=> [
				for(e: it) {
//					switch e {
//						ExplorableWithSender: senders.put(e.origin, e.sender)
//					}
					times.put(e.origin, e.originTime)
				}
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
			+ explorableFromOthers
		)
		
		// normalize them over the 24 directions
		RelativeCoordinates.SENSORS_DIRECTIONS_CONES
			.map[p|explo.filter[coord.value.between(p.cone)]]
			.filter[!empty]
			.map[
				// TODO what if we skip things that have meaning for others?!
				// for equivalent criticality of course...
				maximum(explorableCriticalityOrd)
			]
			=> [
				logger.info("explorable: {}", it)
			]
	}
	
	def buildSeen(RelativeCoordinates coord) {
		// reduce criticality of visible place where I come from?
		// TODO maybe smooth it a little?
		new Explorable(
			coord,
//			if (requires.perceptions.goingBack(coord))
//				Constants.STARTING_EXPLORABLE_CRITICALITY/2.0
//			else
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