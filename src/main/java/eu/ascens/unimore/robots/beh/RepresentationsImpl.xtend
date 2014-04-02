package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableImpl
import eu.ascens.unimore.robots.beh.datatypes.MySeenVictim
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.common.SeenVictim
import fj.P
import fj.data.List
import fj.function.Integers
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.beh.Utils.*
import static extension eu.ascens.unimore.robots.common.GeometryExtensions.*
import static extension eu.ascens.unimore.robots.common.VictimVision.*
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
	
	@Cached
	override List<SeenVictim> seenVictims() {
		requires.perceptions.visibleVictims.map[v|
			v.toSeenVictim(requires.perceptions.visibleRobots,requires.perceptions.visibleVictims)
		]
	}
	
	@Cached
	def List<MySeenVictim> myConsideredVictims() {
		seenVictims
			.filter[inNeed]
			.map[MySeenVictim.fromSeenVictim(it, direction.shouldBeResponsibleOf)]
	}
	
	override List<SeenVictim> consideredVictims() {
		myConsideredVictims.vary
	}
	
	private def boolean shouldBeResponsibleOf(Double2D dir) {
		val myDistToDirSq = dir.lengthSq
		!requires.perceptions.visibleRobots.exists[
			coord.isCloserThanMe(coord.distanceSq(dir), myDistToDirSq)
		]
	}
	
	@Cached
	private def List<Explorable> explorablesFromVictims() {
		val victims = myConsideredVictims
						.filter[howMuch < nbBotsNeeded]
						.filter[imResponsible]
		if (victims.notEmpty) {
			val nb = Integers.sum(victims.map[
				nbBotsNeeded - howMuch - (if (imNext) 0 else 1)
			])
			val crit = Math.pow(2, nb)
			val worst = victims.mostInNeedVictim
			val sr = requires.perceptions.sensorReadings.find[sr|
				worst.direction.between(sr.cone)
			].some()
			List.list(ExplorableImpl.build(
				sr.dir.resize(worst.direction.length),
				crit,
				requires.perceptions.myId
			))
		} else List.nil
		// TODO this one is weak, because if there is 4 victims, only one could be
		// taken into account : the problem is maybe how crit is computed then!
		// this shouldn't be based on the number of people, is it?
//		requires.perceptions.sensorReadings
//		.bind[sr|
//			val victimsInDirectionOfSR = consideredVictims.filter[
//				direction.between(sr.cone) && direction.shouldBeResponsibleOf
//			]
//			if (victimsInDirectionOfSR.notEmpty) {
//				val nb = Integers.sum(victimsInDirectionOfSR.map[
//					nbBotsNeeded - howMuch - (if (imNext) 0 else 1)
//				])
//				val crit = Math.pow(2, nb)
//				val dist = Doubles.sum(victimsInDirectionOfSR.map[direction.length])/victimsInDirectionOfSR.length
//				List.list(new Explorable(
//					sr.dir.resize(dist),
//					crit,
//					requires.perceptions.myId
//				))
//			} else List.nil
//			if (victimsInDirectionOfSR.notEmpty) {
//				val worst = victimsInDirectionOfSR.mostInNeedVictim
//				val crit = Math.pow(
//					2,
//					worst.nbBotsNeeded - worst.howMuch - (if (worst.imNext) 0 else 1)
//				)
//				List.list(new Explorable(
//					sr.dir.resize(worst.direction.length),
//					crit,
//					requires.perceptions.myId
//				))
//			} else List.nil
//		]
	}
	
	@Cached
	override List<Explorable> seenAreas() {
		requires.perceptions.sensorReadings
		.bind[sr|
			if (sr.dir.shouldBeResponsibleOf) {
				val crit = if (sr.hasWall) 0.0 else 0.5 // this is 1/Math.pow(2,1) to count me
				List.<Explorable>list(ExplorableImpl.build(
					sr.dir,
					crit,
					requires.perceptions.myId
				))
			} else List.nil
		]
	}
	
	
	
	@Cached
	override List<Explorable> explorableFromOthers() {
		val msgOfInterest = requires.perceptions.receivedMessages
								.filter[
									explorable.gotItFrom != requires.perceptions.myId
									&& explorable.origin != requires.perceptions.myId
								]
		
		msgOfInterest.map[re|
			
			val othersToCount = msgOfInterest.filter[
				// count those that are NOT on victims
				!onVictim
				// and going to the the same place
				&& explorable.origin == re.explorable.origin
				// and those closer than me to the chosen direction
				//&& from.coord.isCloserThanMe(from.coord.distanceSq(realDir), realDir.lengthSq)
				&& explorable.traveled < (re.explorable.traveled + re.from.coord.length)
			].map[from]
			
			val crit = re.explorable.criticality / Math.pow(2, othersToCount.length + 1)
			
			P.p(re, crit, othersToCount)
		].keepMaxEquivalents[_2]
		.map[
			val sr = {
				val nc = _1.explorable.direction+_1.from.coord
				val psr = nc.sensorReading
				if (psr.hasWall) {
					_1.from.coord.sensorReading
				} else {
					psr
				}
			}
			_1.toExplorable(sr.dir, _2, _3)
		]
		
//		requires.perceptions.sensorReadings
//		.bind[sr|
//			val othersInDirectionOfSR = receivedExplorableFromOthers.filter[explorable.direction.between(sr.cone)]
//			if (othersInDirectionOfSR.notEmpty) {
//				// TODO handle equivalents
//				// TODO take into account the computation of crit from under to actually
//				// choose :)
//				val worst = othersInDirectionOfSR.maximum(explorableCriticalityOrd.comap[explorable]).explorable
//				val realDir = worst.direction
//				// the problem here is that those of interest
//				// do not seem to be in the same SR cone...
//				val othersInDirectionOfSRToCount = othersInDirectionOfSR.filter[
//					val from = worst.via.some()
//					// do not count those that are on victims
//					!onVictim
//					// and those behind me wrt the chosen one
//					&& from.isCloserThanMe(from.coord.distanceSq(realDir), realDir.lengthSq)
//				].map[explorable.via.some()]
//				
//				val crit = worst.criticality
//								/ Math.pow(2, othersInDirectionOfSRToCount.length + 1)
//				
//				List.list(
//					new Explorable(sr.dir, crit, worst.via, othersInDirectionOfSRToCount, worst.origin)
//				)
//			} else {
//				List.nil
//			}
//		]
	}
	
	private def getSensorReading(Double2D direction) {
		requires.perceptions.sensorReadings
			.find[sr|direction.between(sr.cone)]
			.some()
	}
	
//	// TODO we need anyway to better handle the computation of the direction
//	def Double2D directionFromMyPoV(ReceivedExplorable it) {
//		// is that a good idea... ?
//		val nc = explorable.direction+from.coord
//		doAssert(nc.lengthSq != 0, "bouh")
//		
//		/*
//		val ncLengthSq = nc.lengthSq
//		// this could happen...
//		if (ncLengthSq == 0) {
//			throw new RuntimeException("bouh")
//			//- from.coord // minus because it means it is going toward me!
//		} else {
//			nc
//		}
//		*/
//		nc
//	}
	
	@Cached
	override List<Explorable> explorables() {
		explorableFromOthers + explorablesFromVictims + seenAreas
	}
}