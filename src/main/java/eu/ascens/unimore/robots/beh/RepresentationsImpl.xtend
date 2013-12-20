package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Area
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.Victim
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import sim.util.Double2D

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
	
	private def existsCloserBot(Double2D c) {
		val distToV = c.lengthSq
		requires.perceptions.visibleRobots.exists[b|
			val d = b.coord.distanceSq(c)
			d < distToV
			// in case the distance is the same…
			|| (d == distToV && requires.perceptions.myId < b.id)
		]
	}
	
	private def existsVisibleWall(Double2D c) {
		requires.perceptions.visibleWalls.exists[w|c.between(w.cone)]
	}
	
	@StepCached
	override responsibleVictims() {
		requires.perceptions.visibleVictims
			// do not consider it if there is another robot closer
			.filter[!existsCloserBot]
			.map[v|
				val dist = v.length
				new Victim(
					v,
					dist,
					requires.messaging.currentSig,
					null,
					Constants.STARTING_VICTIM_CRITICALITY,
					null,
					Constants.HOW_MUCH_PER_VICTIM
						// remove other bots close enough to victim
						- requires.perceptions.visibleRobots.count[
							coord.distance(v) <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE
						]
						// remove myself if I'm close enough too
						- (if (dist <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE) 1 else 0)
				)
			]
			// TODO merge all the victims as one (since we are responsible for all of them
			// or try to be responsible of only one victim?!
			// => maybe this would happen when another bot will get closer
			// and this would be the case if he goes around me? because he see a victim
			// and he sees that I am closer to another one? so he decide to get closer to
			// this one!
			
			// TODO when there is a group of victims, often, info about the first ones are transmitted
			// over those about other victims behind... 
	}
	
	@StepCached
	override responsibleSeen() {
		requires.perceptions.visibleFreeAreas
			.map[dir]
			.filter[!existsCloserBot]
			.map[d|
				new Area(
					d,
					0,
					requires.messaging.currentSig,
					null,
					Constants.STARTING_EXPLORABLE_CRITICALITY,
					null
				)
			]
	}
	
	@StepCached
	override explorableFromOthers() {
		requires.messaging.explorationMessages.map[p|
			val nc = p.explorable.direction+p.fromCoord
			val viaLengthSq = p.fromCoord.lengthSq
			val ncLengthSq = nc.lengthSq
			// follow directly the sender if
			val dir = if (
				// the information is useless
				// or he points to something too far from me
				// to correctly assess the direction (it's a sum of vector, length matters)
				ncLengthSq == 0 || ncLengthSq > viaLengthSq
				// or it's facing a wall
				|| existsVisibleWall(nc)
				) p.fromCoord
				else nc
			p.toExplorable(dir)
		]
	}
	
	@StepCached
	override explorables() {
		responsibleSeen
		+ responsibleVictims
		+ explorableFromOthers.removeUninterestingVictims
	}
		
	private def removeUninterestingVictims(List<Explorable> es) {
		es.filter[e|
			switch e {
				// for a victim, I keep it if...
				Victim: {
					// I'm close enough to be considered around the victim and we are not too much
					(e.distance <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE && e.howMuch >= 0)
					// or I'm not considered around the victim and they still need someone
					|| (e.distance > Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE && e.howMuch > 0)
				}
				// TODO would be best if CONSIDERED_NEXT_TO_VICTIM_DISTANCE is not an
				// information pre-shared by agent... maybe could be done exploiting only howMuch?
				// or sharing id of considered in?
				// also, it's not so good because distance is not very reliable
				default: true
			}
		]
	}
}