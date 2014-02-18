package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Area
import eu.ascens.unimore.robots.beh.datatypes.Victim
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.xtend.macros.StepCached
import sim.util.Double2D

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*
import fj.data.List

class RepresentationsImpl extends Representations implements IRepresentationsExtra {
	
	override protected make_preStep() {
		[|preStep]
	}
	
	override protected make_representations() {
		this
	}
	
	@StepCached
	def preStep() {
	}
	
	private def isCloserThanMe(RBEmitter who, double hisDistanceSq, double myDistanceSq) {
		hisDistanceSq < myDistanceSq
		// in case the distance is the same… rare but possible
		|| (hisDistanceSq == myDistanceSq && requires.perceptions.myId < who.id)
	}
	
	private def isConsideredNextTo(Double2D who, Double2D victim) {
		val distToVictSq = who.distanceSq(victim)
		// bot is close enough to victim
		distToVictSq <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			// but not closer to another victim
			&& who.isConsideredCloserTo(distToVictSq)
	}
	
	private def ImConsideredCloserTo(double distToWhatSq) {
		!requires.perceptions.visibleVictims.exists[ov|
			ov.lengthSq < distToWhatSq
		]
	}
	
	private def isConsideredCloserTo(Double2D who, double distToWhatSq) {
		!requires.perceptions.visibleVictims.exists[ov|
			who.distanceSq(ov) < distToWhatSq
		]
	}
	
	private def shouldBeResponsibleOfVictim(Double2D victim) {
		val distToVictSq = victim.lengthSq
		// this is the victim I'm closest to (i.e. I will keep only one?!)
		ImConsideredCloserTo(distToVictSq)
		&& !requires.perceptions.visibleRobots.exists[b|
			val hisDistToVictSq = b.coord.distanceSq(victim)
			// i.e. there is a robot closer than me
			b.isCloserThanMe(hisDistToVictSq, distToVictSq)
				// and he is not already focused on another victim
				&& b.coord.isConsideredCloserTo(hisDistToVictSq)
		]
	}
	
	@Cached
	override responsibleVictims() {
		requires.perceptions.visibleVictims
			// do not consider it if there is enough robots closer 
			.filter[shouldBeResponsibleOfVictim]
			.map[v|
				val dist = v.length
				new Victim(
					v,
					dist,
					requires.messaging.currentSig,
					Constants.STARTING_VICTIM_CRITICALITY,
					// count both that I consider as being focused on this victim
					requires.perceptions.visibleRobots.count[coord.isConsideredNextTo(v)]
					+ (if (dist <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE) 1 else 0)
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
	
	private def shouldBeResponsibleOfArea(Double2D dir) {
		val myDistToVictSq = dir.lengthSq
		!requires.perceptions.visibleRobots.exists[b|
			val histDistToVictSq = b.coord.distanceSq(dir)
			// -0.1 in order to not get problems when bots are at the same distance
			// and some glitch make them both see the other as closer
			// there will be duplicate just for the time of one turn normally
			b.isCloserThanMe(histDistToVictSq, myDistToVictSq - 0.1)
		]
	}
	
	@Cached
	override responsibleSeen() {
		requires.perceptions.visibleFreeAreas
			.map[dir]
			.filter[!Constants.COOPERATION || shouldBeResponsibleOfArea]
			.map[d|
				new Area(
					d,
					d.length,
					requires.messaging.currentSig,
					Constants.STARTING_EXPLORABLE_CRITICALITY
				)
			]
	}
	
	@Cached
	override explorableFromOthers() {
		requires.messaging.explorationMessages
		.map[p|
			val nc = p.explorable.direction+p.fromCoord
			val ncLengthSq = nc.lengthSq
			// follow directly the sender if
			val dir = if (
					// the information is useless
					// or he points to something too far from me
					// to correctly assess the direction (because it's a sum of vector, so length is fuzzy)
					ncLengthSq <= 0 || ncLengthSq > Constants.VISION_RANGE_SQUARED
					// or it's facing a wall
					//|| requires.perceptions.visibleWalls.exists[w|nc.between(w.cone)]
				) p.fromCoord
				else nc
			p.toExplorable(dir)
		]
		.map[e|
			switch e {
				// TODO that is not the best for knowing if we see the victim, distance should be also used...
				// or maybe directly the victims themselves...
				Victim case e.direction.lengthSq <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED: {
					val howMuch = requires.perceptions.visibleRobots.count[coord.isConsideredNextTo(e.direction)]
					e.withHowMuch(howMuch + 1)
				}
				default: e
			}
		]
		.filter[e|
			switch e {
				// if it's a victim, only consider it if there is not enough people
				Victim: {
					if (e.direction.lengthSq < Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED) {
						e.howMuch <= Constants.HOW_MUCH_PER_VICTIM
					} else {
						e.howMuch < Constants.HOW_MUCH_PER_VICTIM
					}
				}
				default: true
			}
		]
	}
	
	@Cached
	override explorables() {
		(if (Constants.COOPERATION) explorableFromOthers else List.nil) +
		responsibleSeen.vary +
		responsibleVictims.vary
	}
}