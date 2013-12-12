package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

class RepresentationsImpl extends Representations implements IRepresentationsExtra {
	
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
			.map[v|
				// TODO reduce if there is a lot of people around?
				new Explorable(
					v,
					0,
					requires.messaging.currentSig,
					null,
					0,
//					if (requires.perceptions.visibleRobots.count[b|b.coord.distanceSq(v) < 6] > 10)
//						Constants.STARTING_VICTIM_CRITICALITY / 2.2
//					else 
						Constants.STARTING_VICTIM_CRITICALITY,
					null
				)
			]
	}
	
	@StepCached
	override explorableSeen() {
		// only keep those where there is no wall
		requires.perceptions.visibleFreeAreas
			.map[
				// reduce criticality of visible place where I come from?
				// TODO maybe smooth it a little?
				// we need something more intelligent here...
				new Explorable(
					dir,
					0,
					requires.messaging.currentSig,
					null,
					0,
//					if (requires.perceptions.goingBack(dir))
//						Constants.STARTING_BACK_EXPLORABLE_CRITICALITY
//					else
						Constants.STARTING_EXPLORABLE_CRITICALITY,
					null
				)
			]
	}
	
	@StepCached
	override responsibleVictims() {
		explorableVictims
			.filter[v|
				// do not consider it if there is another robot closer
				val distToV = v.direction.lengthSq
				requires.perceptions.visibleRobots.forall[b|
					val d = b.coord.distanceSq(v.direction)
					d > distToV
					// in case the distance is the same…
					|| (d == distToV && requires.perceptions.myId > b.id)
				]
			]
	}
	
	@StepCached
	override responsibleSeen() {
		// consider only those from explorationMessages because if not
		// we have hole of vision when we didn't get some messages
		// but we want the info from their actual position so uses data from conesCoveredByVisibleRobots
		//val eM = requires.messaging.explorationMessages
		// -> no need anymore as we use the RB publishing 
		val cones = requires.perceptions.visionConesCoveredByVisibleRobots//.filter[p|eM.exists[key.id == p.key]]
		explorableSeen
			.filter[
				// it is visible only from me
				// i.e. this direction is not covered by others
				!cones.exists[c|direction.between(c.value)]
			]
	}
	
	@StepCached
	override explorableFromOthers() {
		requires.messaging.explorationMessages.map[p|
			val via = p.key
			p.value.map[e|
				val nc = e.direction+via.coord
				val nclSq = nc.lengthSq
				// follow directly the sender if
				val dir = if (
					// the information is useless
					nclSq == 0
					// or he points to something too far from me
					// to correctly assess the direction (it's a sum of vector, length matters)
					|| nclSq > Constants.VISION_RANGE_SQUARED
					// or it's facing a wall
					||requires.perceptions.visibleWalls.exists[w|nc.between(w.cone)])
					via.coord
				else
					nc
				e.via(dir, via)
			]
		].flatten
		.keepOnePerOrigin
	}
	
	@StepCached
	override explorables() {
		responsibleSeen	+ responsibleVictims + explorableFromOthers
	}
}