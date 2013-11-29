package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.SeenExplorableRepresentation
import eu.ascens.unimore.robots.beh.datatypes.VictimRepresentation
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
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
	
	@Step
	def preStep() {}
	
	@StepCached
	override explorableVictims() {
		val res = requires.perceptions.visibleVictims
					.map[new VictimRepresentation(it) as Explorable]
		logger.info("explorableVictims: {}", res)
		res
	}
	
	@StepCached
	override explorableFromMe() {
		// only keep those where there is no wall
		val res = requires.perceptions.sensorReadings
					.filter[!value]
					.map[new SeenExplorableRepresentation(key) as Explorable]
		logger.info("explorableFromMe: {}", res)
		res
	}
	
	@StepCached
	override explorableOnlyFromMe() {
		// consider only those from explorationMessages because if not
		// we have hole of vision when we didn't get some messages
		// but we want the info from their actual position so uses data from conesCoveredByVisibleRobots
		val eM = requires.perceptions.explorationMessages
		val cones = requires.perceptions.conesCoveredByVisibleRobots.filter[p|eM.exists[it.key.id == p.key]]
		val res = explorableFromMe.filter[d|
			// it is explorable only from me
			// if this direction is not covered by others
			!cones.exists[c|d.coord.value.between(c.value.cone)]
		]
		logger.info("explorableOnlyFromMe: {}", res)
		res
	}

	@StepCached
	override explorableFromOthers() {
		val res = requires.perceptions.explorationMessages.map[p|
			val mess = p.value
			// note: this vector is consistent with the position
			// of the emitter when he sent them
			// also contains the cone covered
			val myConeFromHim = mess.others.get(requires.perceptions.myId)
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
					e.maximum(strictExplorableCriticalityOrd).aggregates(p.key, e)
				}
		].filter([it != null])
		logger.info("explorableFromOthers: {}", res)
		res
	}
	
	@StepCached
	override explorables() {
		
		val explo = (
			explorableOnlyFromMe
			+ explorableFromOthers
			+ explorableVictims
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