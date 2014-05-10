package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.SimulationConstants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableFromVictim
import eu.ascens.unimore.robots.beh.datatypes.ExplorableImpl
import eu.ascens.unimore.robots.beh.interfaces.IRepresentationsExtra
import eu.ascens.unimore.robots.common.SeenVictim
import fj.P
import fj.data.List
import fj.function.Integers
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import sim.util.Double2D

import static extension eu.ascens.unimore.robots.common.GeometryExtensions.*
import static extension eu.ascens.unimore.robots.common.VictimVision.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class RepresentationsImpl extends Representations implements IRepresentationsExtra {
	
	val boolean withVictim
	
	new(boolean withVictim) {
		this.withVictim = withVictim
	}
	
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
	override List<SeenVictim> consideredVictims() {
		seenVictims.filter[needMe]
	}
	
	@Cached
	private def List<Explorable> explorablesFromVictims() {
		
		if (!withVictim) {
			return List.nil
		}
		// victims I need to advertise about
		val victims = seenVictims.filter[inNeed]
		
		// it is needed to only advertise if there is a victim
		// I'm responsible of so that there is no duplicates
		// about advertisement (for origin)
		val victimsImResponsibleOf = victims.filter[imClosest]

		if (victimsImResponsibleOf.notEmpty) {
						
			// consider all victims in need
			val nb = Integers.sum(victims.map[nbBotsNeeded - howMuch])
			
			val worst = victimsImResponsibleOf.mostInNeedVictim
			
			val crit = computeVictimCrit(nb)
			
			List.list(ExplorableFromVictim.build(
				worst.direction,
				crit,
				requires.perceptions.myId,
				worst
			))
		} else List.nil
	}
	
	private def boolean shouldBeResponsibleOf(Double2D dir) {
		val myDistToDirSq = dir.lengthSq
		!requires.perceptions.visibleRobots.exists[
			coord.isCloserThanMe(coord.distanceSq(dir), myDistToDirSq)
		]
	}
	
	@Cached
	override List<Explorable> seenAreas() {
		requires.perceptions.sensorReadings
			.bind[sr|
				if (!sr.hasWall && sr.dir.shouldBeResponsibleOf) {
					val crit = 1
					List.<Explorable>list(ExplorableImpl.build(
						sr.dir,
						crit,
						requires.perceptions.myId
					))
				} else {
					List.nil
				}
			]
	}
	
	@Cached
	override List<Explorable> explorableFromOthers() {
		
		val msgOfInterest = requires.perceptions.receivedMessages.filter[
			explorable.gotItFrom != requires.perceptions.myId
			&& explorable.origin != requires.perceptions.myId
		]
		
		// keep those that travelled the less: there should be one per origin
		// thus it will be the most precise, and most certainly the most critical
		val msgToConsider = msgOfInterest.filter[mc|
			!msgOfInterest.exists[
				explorable.origin == mc.explorable.origin
				&& explorable.traveled < mc.explorable.traveled
				//&& from.lengthSq < mc.from.lengthSq
			]
		]
		
		msgToConsider
			.map[
				val target = if (
						// I should see what he points to (or it is behind him and it's as good)
						// correct to use constant because WALL RANGE is the max, that's all
						from.lengthSq < SimulationConstants.WALL_RANGE_SQUARED
						// it's behind him, so I can point to where he points and it's quite precise
						|| explorable.direction.dot(from) > 0) {
					from + explorable.direction
				} else { 	// he points toward me, it's difficult to precisely know where it is
							// best is to follow him... maybe best would be to ignore??
					from
				}
				P.p(it, target)
			]
			.filter[_2.lengthSq > 0]
			.map[mc,target|
				// we must consider that whatever is shared is something we don't see!
				// if it's a victim and I see it, what I see will take precedence anyway (will it?)
				// it can't be a visible area!
				//val sr = target.sensorReading
				
				val othersToCount = msgOfInterest.filter[
					// count those that are NOT on victims
					// TODO instead bot could update what they send depending on
					// the fact that they go to a victim or not, i.e. AFTER selection the explorable
					// BUT maybe not, here onVictim is used to count, not to know if mc must be reduced...
					!onVictim // TODO this is the only place where it is used now...
					// and going to the the same place
					&& explorable.origin == mc.explorable.origin
					// and those closer than me to the chosen direction
					&& from.isCloserThanMe(from.distanceSq(target), target.lengthSq)
					//&& from.dot(realDir) > 0
				].map[from]
				
				val crit = computeNewCrit(mc.explorable.criticality, othersToCount.length)
				
				// correct to use constant because WALL RANGE is the max, that's all
				mc.toExplorable(target.resize(SimulationConstants.WALL_RANGE), crit, othersToCount)
			]
	}
	
	private def getSensorReading(Double2D direction) {
		requires.perceptions.sensorReadings
			.find[sr|direction.between(sr.cone)]
			.some()
	}
	
	private def computeVictimCrit(int howManyVictims) {
		Math.pow(2, howManyVictims)
	}
	
	private def computeNewCrit(double oldCrit, int howMuchAreGoingThere) {
		oldCrit / computeVictimCrit(howMuchAreGoingThere)
	}
	
	@Cached
	override List<Explorable> explorables() {
		explorableFromOthers + explorablesFromVictims + seenAreas
	}
}