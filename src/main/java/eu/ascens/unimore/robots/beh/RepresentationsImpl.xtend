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
	
	private def closerThanMe(RBEmitter who, Double2D what, double myDistanceSq) {
		val dSq = who.coord.distanceSq(what)
		dSq < myDistanceSq
		// in case the distance is the same…
		|| (dSq == myDistanceSq && requires.perceptions.myId < who.id)
	}
	
	@Cached
	override responsibleVictims() {
		requires.perceptions.visibleVictims
			// do not consider it if there is enough robot closer 
			.filter[c|
				val distToV = c.lengthSq
				!requires.perceptions.visibleRobots.exists[closerThanMe(c, distToV)]
			].map[v|
				val dist = v.length
				new Victim(
					v,
					dist,
					requires.messaging.currentSig,
					Constants.STARTING_VICTIM_CRITICALITY,
					// count other bots close enough to victim
					// but not closer to another victim
					requires.perceptions.visibleRobots.count[b|
						val distToVict = b.coord.distance(v)
						distToVict <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE
						// TODO this has to be done in concordance with others behaviours...
						&& !requires.perceptions.visibleVictims.exists[ov|
							ov.distance(b.coord) < distToVict
						]
					]
					// add myself if I'm close enough too
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
	
	@Cached
	override responsibleSeen() {
		requires.perceptions.visibleFreeAreas
			.map[dir]
			.filter[c|
				val distToV = c.lengthSq
				// -0.5 in order to not get problems when bots are at the same distance
				// and some glitch make them both see the other as closer
				// there will be duplicate just for the time of one turn normally
				!requires.perceptions.visibleRobots.exists[closerThanMe(c, distToV - 0.5)]
			]
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
			val viaLengthSq = p.fromCoord.lengthSq
			val ncLengthSq = nc.lengthSq
			// follow directly the sender if
			val dir = if (
					// the information is useless
					// or he points to something too far from me
					// to correctly assess the direction (because it's a sum of vector, so length is fuzzy)
					ncLengthSq == 0 || ncLengthSq > viaLengthSq
					// or it's facing a wall
					//|| requires.perceptions.visibleWalls.exists[w|nc.between(w.cone)]
				) p.fromCoord
				else nc
			p.toExplorable(dir)
		].filter[e|
			switch e {
				// if it's a victim, only consider it if there is not enough people
				Victim: {
					if (e.direction.length < Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE) {
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
		explorableFromOthers +
		responsibleSeen.vary +
		responsibleVictims.vary
	}
}