package eu.ascens.unimore.robots.beh

import org.slf4j.LoggerFactory
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu

/*
 * Note
 * 
 * 1) si la finalité est de faire des chaines, il ne feront pas mieux que ça, et certainement pire
 *  -> pas de finalité (où finalité très qualitative) et émergence : des chaines emergent, mais peuvent faire mieux dans situations extremes
 * 2) difficile à faire car
 *  a) émergence doit faire quelque chose de bien ! commet ? cooperation principalement...
 *  b) le concepteur ne pourra jamais se débarasser d'une finalité ou d'un désir de voir apparaitre des trucs prévus
 * 3) les capacités d'interaction de base (i.e. la définition du pb) aura un impact extremement important sur comment approcher le problème
 *  -> si agent peut voir chemins et reconnaitre salle, l'approche sera de choisir le bon chemin entre des salles, alors que si voit que mur ou pas mur, l'approche sera plus bas niveau
 *  -> lorsque l'on experimente en tant que chercheur, ça pose problème !!!
 * 
 */ 
 
 /*
  * problems:
  * 
  * 1) dès que y en a un qui voit une victime ils crient tous : moi moi moi je le vois
  * et tout le monde se court après et forment une ronde :D
  * 
  * 2) quand ils se séparent, si ya 2 stream d'agents un peu opposé, ils se renforcent
  * parce qu'ils vont que dans la direction inverse du plus...
  * 
  * 3) les agents ne font pas vraiment la diff entre là d'où ils viennent et là où ils vont
  * il faudrait plus de mémoire pour qu'ils se déplacent en groupe plus vite
  * 
  * prez:

milestones (fonctionalités : explorer, trouver, appeler les autres, retrouver maison et ramener)
et pour chaque problèmes (non-fonctionnel : explorer en se séparant, trouver et ne pas s'aglutiner, retrouver maison de façon efficace, etc)

détailler un peu plus les milestones et expliquer qu'on avance le dev jusqu'à en atteindre une et on se concentre sur les problèmes, puis on ocntinue-

On documente la solution du problème, on en tire des conclusions
  * 
  */
//@DisableStepCached
class BehaviourImpl extends ComposedBehaviour implements RobotVisu {
	
	val logger = LoggerFactory.getLogger("agent")
	
	// this prevent the bug with inner classes from appearing
	// by populating the import section with the Component qname
	def neverCalled() {
		newComponent(null)
	}
	
	override protected make_d() {
		new DecisionsImpl
	}
	
	override protected make_r() {
		new RepresentationsImpl
	}
	
	override protected make_ap() {
		new ActionsPerceptionsImpl
	}
	
	override protected make_visu() {
		this
	}
	
	override protected make_step() {
		[|
			logger.info("\n\n-----------------------")
			parts.ap.preStep.doIt
			parts.r.preStep.doIt
			parts.d.step.doIt
		]
	}
	
	override choice() {
		parts.d.decisions.lastChoice
	}
	
	override visibleBots() {
		parts.ap.perceptions.conesCoveredByVisibleRobots.map[value]
	}
	
	override explorables() {
		parts.r.representations.explorables
	}
	
	override explorablesOnlyFromMe() {
		parts.r.representations.explorableOnlyFromMe
	}
	
	override explorablesFromOthers() {
		parts.r.representations.explorableFromOthers
	}
	
}
