package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.VisibleVictim
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import eu.ascens.unimore.xtend.macros.StepCached
import fj.Ord
import fj.P
import fj.data.List
import fj.data.Option
import sim.util.Double2D

import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*
import eu.ascens.unimore.robots.Constants

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
	
	/* Victim stuffs */
	
	/** 
	 * This strongly relies on the fact that bots actually
	 * stops closer to the victim they chose when there is several of them!
	 * @See CoopConstants.STOP_NEXT_TO_VICTIM_DISTANCE also
	 */ 
	private def isConsideredNextTo(Double2D who, double hisDistToVictSq) {
		// bot is close enough to victim
		hisDistToVictSq <= CoopConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			// but not closer to another victim
			&& who.isCloserTo(hisDistToVictSq)
	}
	
	private def isCloserTo(Double2D who, double distToWhatSq) {
		!requires.perceptions.visibleVictims.exists[ov|
			who.distanceSq(ov) < distToWhatSq
		]
	}
	
	@Cached
	override visibleVictims() {
		requires.perceptions.visibleVictims
		.map[v|
			val myDistToVictSq = v.lengthSq
			val ImNext = new Double2D(0,0).isConsideredNextTo(myDistToVictSq)
			new VisibleVictim(v,
				requires.perceptions.visibleRobots.count[
					val hisDistToVictSq = coord.distanceSq(v)
					coord.isConsideredNextTo(hisDistToVictSq)
					// only consider those that are closer than me
					//&& hisDistToVictSq < myDistToVictSq
				] + (if (ImNext) 1 else 0),
				ImNext
			)
		]
	}
	
	@Cached
	override consideredVictims() {
		visibleVictims.filter[
			if (imNext) howMuch <= CoopConstants.HOW_MUCH_PER_VICTIM
			else howMuch < CoopConstants.HOW_MUCH_PER_VICTIM
		]
	}
	
	/* Area stuffs */
	
	private def shouldBeResponsibleOf(Double2D dir) {
		val myDistToDirSq = dir.lengthSq
		!requires.perceptions.visibleRobots.exists[b|
			val hisDistToDirSq = b.coord.distanceSq(dir)
			// -0.1 in order to not get problems when bots are at the same distance
			// and some glitch make them both see the other as closer
			// there will be duplicate just for the time of one turn normally
			hisDistToDirSq < myDistToDirSq
			|| (hisDistToDirSq == myDistToDirSq && b.id < requires.perceptions.myId)
		]
	}
	
	@Cached
	override responsibleSeen() {
		requires.perceptions.sensorReadings
			// note: bind is flatMap
			.bind[sr|
				if (!CoopConstants.COOPERATION) {
					if (!sr.hasWall) {
						List.single(P.p(sr.dir, CoopConstants.STARTING_EXPLORABLE_CRITICALITY))
					} else {
						List.nil
					}
				} else {
					val victDirAndCrit = sr.criticalityForDirectionFromVictims
					if (victDirAndCrit.isSome){
						if (victDirAndCrit.some()._1.shouldBeResponsibleOf) {
							List.single(victDirAndCrit.some())
						} else {
							List.nil
						}
					} else {
						if (!sr.hasWall && sr.dir.shouldBeResponsibleOf) {
							List.single(P.p(sr.dir, CoopConstants.STARTING_EXPLORABLE_CRITICALITY))
						} else {
							List.nil
						}
					}
				}
			]
			.map[
				new Explorable(
					_1,
					requires.messaging.currentSig,
					_2
				)
			]
	}
	
	/**
	 * Compute criticality to add to direction based on victims
	 * Return none if there is no victim of interest in that direction
	 */
	private def criticalityForDirectionFromVictims(SensorReading sr) {
		val victimsInDirectioOfSR = consideredVictims.filter[direction.between(sr.cone)]
		if (victimsInDirectioOfSR.empty) {
			Option.none
		} else {
			val worst = victimsInDirectioOfSR.minimum(Ord.intOrd.comap[howMuch])
			Option.some(
				P.p(worst.direction,
					CoopConstants.STARTING_EXPLORABLE_CRITICALITY + 
					Math.max(
						0.0,
						(CoopConstants.HOW_MUCH_PER_VICTIM - worst.howMuch)
							*CoopConstants.VICTIM_SLICE_CRITICALITY
					)
				)
			)
		}
	}
	
	// TODO unify CRIT computation!
	
	@Cached
	override explorableFromOthers() {
		// TODO maybe would be best to take the message
		// that has travelled the less, but the message
		// the closer to me for a same origin?
		// or just the most critical (it will then take care of loops...)
		requires.messaging.explorationMessages.map[p|
			val nc = p.explorable.direction+p.from.coord
			val ncLengthSq = nc.lengthSq
			// to correctly assess the direction
			// because it's a sum of vector, so length is unreliable
			// TODO this is not very good as it is…
			val newDir = if (ncLengthSq > Constants.WALL_RANGE) {
				// stop closer if it points to something too far from me
				nc.resize(Constants.WALL_RANGE)
			} else if (ncLengthSq <= 0) {
				// follow directly the sender if the information is useless
				p.from.coord
			} else {
				nc
			}
			val newCrit = Math.max(
								CoopConstants.STARTING_EXPLORABLE_CRITICALITY,
								p.explorable.criticality-CoopConstants.VICTIM_SLICE_CRITICALITY*p.fromHowMany
							)
			p.toExplorable(newDir, newCrit)
		]
	}
	
	@Cached
	override explorables() {
		(if (CoopConstants.COOPERATION) explorableFromOthers else List.nil) +
		responsibleSeen
	}
}