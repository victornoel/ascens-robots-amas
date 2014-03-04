package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.RequirementsConstants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ReceivedExplorable
import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.data.List
import fj.data.Option
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static eu.ascens.unimore.robots.beh.Utils.*

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class RepresentationsImpl extends Representations implements IRepresentationsExtra {
	
	override protected make_preStep() {
		[|preStep]
	}
	
	override protected make_representations() {
		this
	}
	
	@StepCached
	def void preStep() {
	}
	
	/* Victim stuffs */
	
	/** 
	 * This strongly relies on the fact that bots actually
	 * stops closer to the victim they chose when there is several of them!
	 * @See CoopConstants.STOP_NEXT_TO_VICTIM_DISTANCE also
	 */
	private def isConsideredNextTo(Double2D who, double hisDistToVictSq) {
		// bot is close enough to victim
		hisDistToVictSq <= RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			// but not closer to another victim
			&& who.isCloserTo(hisDistToVictSq)
	}
	
	private def isCloserTo(Double2D who, double distToWhatSq) {
		!requires.perceptions.visibleVictims.exists[ov|
			who.distanceSq(ov.dir) < distToWhatSq
		]
	}
	
	@Cached
	override List<SeenVictim> seenVictims() {
		requires.perceptions.visibleVictims
		.map[v|
			val myDistToVictSq = v.dir.lengthSq
			val ImNext = new Double2D(0,0).isConsideredNextTo(myDistToVictSq)
			new SeenVictim(
				v.dir,
				requires.perceptions.visibleRobots
					.count[
						coord.isConsideredNextTo(coord.distanceSq(v.dir))
					] + (if (ImNext) 1 else 0),
				v.nbBotsNeeded,
				ImNext
			)
		]
	}
	
	@Cached
	override List<SeenVictim> consideredVictims() {
		seenVictims.filter[
			if (imNext) howMuch <= nbBotsNeeded
			else howMuch < nbBotsNeeded
		]
	}
	
	private def isCloserThanMe(RBEmitter him, double hisDistToDirSq, double myDistToDirSq) {
		hisDistToDirSq < myDistToDirSq
			|| (hisDistToDirSq == myDistToDirSq
				// in case we have the same dist, take the one the more on the east
				// or if same the more on the south
				&& (him.coord.x > 0
					|| (him.coord.x == 0 && him.coord.y > 0)
				)
			)
	}
	
	/* Area stuffs */
	
	private def shouldBeResponsibleOf(Double2D dir) {
		val myDistToDirSq = dir.lengthSq
		!requires.perceptions.visibleRobots.exists[
			isCloserThanMe(coord.distanceSq(dir), myDistToDirSq)
		]
	}
	
	@Cached
	override List<Explorable> seenAreas() {
		requires.perceptions.sensorReadings
		// note: bind is flatMap
		.bind[sr|
			val victDirAndCrit = sr.criticalityForDirectionFromVictims
			val otherDirAndCrit = sr.criticalityForDirectionFromOthers
			val toConsider = List.list(
				if (victDirAndCrit.isSome && victDirAndCrit.some().direction.shouldBeResponsibleOf){
					List.list(victDirAndCrit.some())
				} else {
					List.nil
				},
				if (otherDirAndCrit.isSome) {
					List.list(otherDirAndCrit.some())
				} else {
					List.nil
				}
			).flatten
			if (toConsider.notEmpty) {
				List.single(toConsider.maximum(explorableCriticalityOrd))
			} else if (!sr.hasWall && sr.dir.shouldBeResponsibleOf) {
				List.single(
					new Explorable(sr.dir, CoopConstants.STARTING_EXPLORABLE_CRITICALITY, 0)
				)
			} else {
				List.nil
			}
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
			val worst = victimsInDirectioOfSR.mostImportantVictim
			val slice = CoopConstants.VICTIM_RANGE_CRITICALITY/(worst.nbBotsNeeded as double)
			val crit = CoopConstants.STARTING_EXPLORABLE_CRITICALITY + 
						// TODO WRONG?
						Math.max(0.0,
								((worst.nbBotsNeeded as double) - (worst.howMuch as double))*slice
						)
			Option.some(new Explorable(worst.direction, crit, slice))
		}
	}
	
	private def criticalityForDirectionFromOthers(SensorReading sr) {
		val othersInDirectionOfSr = explorableFromOthers.filter[direction.between(sr.cone)]
		if (othersInDirectionOfSr.empty) {
			Option.none
		} else {
			val worst = othersInDirectionOfSr.maximum(explorableCriticalityOrd)
			val newCrit =
				if (worst.criticality > CoopConstants.STARTING_EXPLORABLE_CRITICALITY + 0.02)
					{
						Math.max(
							// the +0.01 is needed so that we follow this one more than
							// any 0.5 one because it was already more than 0.5...
							CoopConstants.STARTING_EXPLORABLE_CRITICALITY+0.01,
							worst.criticality-worst.victimSlice*othersInDirectionOfSr.size
						)
					}
				else {
					CoopConstants.STARTING_EXPLORABLE_CRITICALITY
				}
			Option.some(worst.withCriticality(newCrit))
		}
	}
	
	// TODO unify CRIT computation!
	
	@Cached
	override List<Explorable> explorableFromOthers() {
		// TODO maybe would be best to take the message
		// that has travelled the less, but the message
		// the closer to me for a same origin?
		// or just the most critical (it will then take care of loops...)
		requires.messaging.explorationMessages
		.map[re|
			val newDir = re.computeRealDirFromExplorable
			// TODO I should only take into account the closest to the destination
			// than me, but how to compute that... !
			// and how do I distinguish between various people going to the same place?
			// maybe uniformise on my sensorReadings?
			// TODO also we could consider not going somewhere if there is people already
			// going in that direction even though I'm closer (i.e. not go back)
			
			// TODO what I should do is consider that this crit more important
			// than other equivalent crits in case I go into the first part of the if
			
			re.toExplorable(newDir, re.explorable.criticality)
		]
	}
	
	// TODO we need anyway to better handle the computation of the direction
	private def computeRealDirFromExplorable(ReceivedExplorable re) {
		// is that a good idea... ?
		val nc = re.explorable.direction+re.from.coord
		val ncLengthSq = nc.lengthSq
		// this could happen...
		if (ncLengthSq == 0) {
			re.from.coord
		} else if (ncLengthSq > re.from.coord.lengthSq) {
			// TODO not so good...
			nc.resize(re.from.coord.length)
		} else {
			nc
		}
	}
	
	@Cached
	override List<Explorable> explorables() {
		//explorableFromOthers +
		seenAreas
	}
}