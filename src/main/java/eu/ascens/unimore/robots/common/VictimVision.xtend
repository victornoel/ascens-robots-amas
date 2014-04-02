package eu.ascens.unimore.robots.common

import eu.ascens.unimore.robots.RequirementsConstants
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import eu.ascens.unimore.robots.mason.datatypes.VisibleVictim
import fj.data.List
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*
import fj.Ord

import static extension eu.ascens.unimore.robots.common.GeometryExtensions.*

class VictimVision {
	
	@Pure
	public static def toSeenVictim(VisibleVictim v, List<RBEmitter> visibleRobots, List<VisibleVictim> visibleVictims) {
		val myDistToVictSq = v.dir.lengthSq
			val imNext = new Double2D(0,0).isConsideredNextTo(v, myDistToVictSq, visibleVictims)
			val howMuch = visibleRobots
							.count[
								coord.isConsideredNextTo(v, coord.distanceSq(v.dir), visibleVictims)
							] + (if (imNext) 1 else 0)
			new SeenVictim(
				v.dir,
				howMuch,
				v.nbBotsNeeded,
				imNext,
				if (imNext) howMuch <= v.nbBotsNeeded else howMuch < v.nbBotsNeeded
			)
	}
	
	/** 
	 * This strongly relies on the fact that bots actually
	 * stops closer to the victim they chose when there is several of them!
	 */
	@Pure
	private static def isConsideredNextTo(Double2D who, VisibleVictim v, double hisDistToVictSq, List<VisibleVictim> visibleVictims) {
		// bot is close enough to victim
		hisDistToVictSq <= RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED
			// but not closer to another victim
			&& who.isCloserTo(v, hisDistToVictSq, visibleVictims)
	}
	
	@Pure
	private static def isCloserTo(Double2D who, VisibleVictim v, double distToWhatSq, List<VisibleVictim> visibleVictims) {
		!visibleVictims.exists[ov|
			ov !== v
			&& who.isCloserThanMe(who.distanceSq(ov.dir), distToWhatSq)
		]
	}
	
	/**
	 * First tries to secure before trying to go
	 * For another victim: the idea is that a saved victim
	 * is more important than two discovered victims
	 * Consider closest victims in most need
	 */
	@Pure
	public static def <V extends SeenVictim> mostInNeedVictim(List<V> victims) {
		victims.maximum(
			Ord.doubleOrd.comap[V it|
				val hm = howMuch - (if (imNext) 1 else 0)
				(hm as double)/(nbBotsNeeded as double)
			] || Ord.doubleOrd.comap[V it|-direction.lengthSq]
		)
	}
	
}