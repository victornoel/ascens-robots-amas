package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Area
import eu.ascens.unimore.robots.beh.datatypes.Victim
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.xtend.macros.Step
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
				new Victim(
					v,
					v.length,
					requires.messaging.currentSig,
					null,
					Math.max(0, 
						Constants.HOW_MUCH_PER_VICTIM - requires.perceptions.visibleRobots.count[
							coord.distance(v) <= Constants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE
						]
					),
					Constants.STARTING_VICTIM_CRITICALITY,
					null
				)
			]
			// TODO merge all the victims as one (since we are responsible for all of them
			// or try to be responsible of only one victim?!
			// => maybe this would happen when another bot will get closer
			// and this would be the case if he goes around me? because he see a victim
			// and he sees that I am closer to another one? so he decide to get closer to
			// this one!
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
					0,
					Constants.STARTING_EXPLORABLE_CRITICALITY,
					null
				)
			]
	}
	
	@StepCached
	override explorableFromOthers() {
		requires.messaging.explorationMessages.map[p|
			val via = p.key
			p.value.map[e|
				val nc = e.direction+via.coord
				val viaLengthSq = via.coord.lengthSq
				val ncLengthSq = nc.lengthSq
				// follow directly the sender if
				val dir = if (
					// the information is useless
					// or he points to something too far from me
					// to correctly assess the direction (it's a sum of vector, length matters)
					ncLengthSq == 0 || ncLengthSq > viaLengthSq
					// or it's facing a wall
					|| existsVisibleWall(nc)
				) via.coord
				else nc
				e.via(dir, via)
			]
		].flatten
	}
	
	@StepCached
	override explorables() {
		responsibleSeen	+ responsibleVictims + explorableFromOthers
	}
}