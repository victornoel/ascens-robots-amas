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
	
	/** 
	 * This strongly relies on the fact that bots actually
	 * stops closer to the victim they chose when there is several of them!
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
	
	private def boolean shouldBeResponsibleOf(Double2D dir) {
		val myDistToDirSq = dir.lengthSq
		!requires.perceptions.visibleRobots.exists[
			isCloserThanMe(coord.distanceSq(dir), myDistToDirSq)
		]
	}
	
	/**
	 * To avoid recomputing again and again the same things
	 * in the same step
	 */
	@Cached
	private def SensorReadingData datasFromSensorReading(SensorReading sr) {
		val victimsInDirectionOfSR = consideredVictims.filter[
			direction.between(sr.cone) && direction.shouldBeResponsibleOf
		]
		val othersInDirectionOfSR = receivedExplorableFromOthers.filter[direction.between(sr.cone)]
		val nbOthersInDirectionOfSR = othersInDirectionOfSR.length
		new SensorReadingData(
			victimsInDirectionOfSR,
			othersInDirectionOfSR,
			nbOthersInDirectionOfSR,
			sr.dir.shouldBeResponsibleOf
		)
	}
	
	@Cached
	private def List<Explorable> explorablesFromVictims() {
		requires.perceptions.sensorReadings
		.bind[sr|
			val datas = sr.datasFromSensorReading
			if (datas.victims.notEmpty) {
				val worst = datas.victims.mostInNeedVictim
				
				val slice = CoopConstants.VICTIM_RANGE_CRITICALITY/worst.nbBotsNeeded
				val crit = CoopConstants.STARTING_EXPLORABLE_CRITICALITY + 
							Math.max(0.0, (worst.nbBotsNeeded - worst.howMuch)*slice)
				List.list(new Explorable(sr.dir.resize(worst.direction.length), crit, slice))
			} else List.nil
		]
	}
	
	@Cached
	override List<Explorable> seenAreas() {
		requires.perceptions.visibleFreeAreas
		.bindIdx[sr,i|
			val datas = sr.datasFromSensorReading
			if (datas.shouldBeResponsible) {
				val crit = Math.max(0.0, CoopConstants.STARTING_EXPLORABLE_CRITICALITY - datas.nbOthers*0.05)
				List.list(new Explorable(sr.dir, crit, 0))
			} else List.nil
		]
	}
	
	@Cached
	def List<Explorable> receivedExplorableFromOthers() {
		requires.messaging.explorationMessages
		.map[re|
			re.toExplorable(re.computeRealDirFromExplorable)
		]
	}
	
	@Cached
	override List<Explorable> explorableFromOthers() {
		requires.perceptions.sensorReadings
		.bind[sr|
			val datas = sr.datasFromSensorReading
			if (datas.others.notEmpty) {
				val worst = datas.others.maximum(explorableCriticalityOrd)
				val newCrit =
					if (worst.criticality > CoopConstants.STARTING_EXPLORABLE_CRITICALITY)
						{
							Math.max(
								CoopConstants.STARTING_EXPLORABLE_CRITICALITY,
								worst.criticality-worst.victimSlice*datas.nbOthers
							)
						}
					else {
						Math.max(0.0, CoopConstants.STARTING_EXPLORABLE_CRITICALITY - datas.nbOthers*0.05)
					}
				List.list(new Explorable(sr.dir, newCrit, worst.victimSlice, worst.via))
			} else List.nil
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
		} else {
			nc
		}
	}
	
	@Cached
	override List<Explorable> explorables() {
		explorableFromOthers + explorablesFromVictims + seenAreas
	}
}

@Data class SensorReadingData {
	val List<SeenVictim> victims
	val List<Explorable> others
	val int nbOthers
	val boolean shouldBeResponsible
}