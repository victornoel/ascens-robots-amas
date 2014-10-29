package eu.ascens.unimore.robots.beh

import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import org.slf4j.LoggerFactory

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
   * il y a des problemes de:
   *  -> celui qui perd sait qu'il y a une victime dans cette direction, pourquoi il continue pas ?
   *   -> on devrait continuer meme si on voit plus l'autre... peut-etre qu'on devrait utiliser l'info quand meme !
   * 
   * 3) les agents ne font pas vraiment la diff entre là d'où ils viennent et là où ils vont
   * il faudrait plus de mémoire pour qu'ils se déplacent en groupe plus vite
   *  -> ici l'idée serait qu'un agent est responsable d'un endroit qu'il voit
   * et donc sur le temps, il pourrait évaluer sa criticité àa la baisse si pertinent
   * 
   * il faut une info supplémentaire pour choisir entre 2 trucs... peut-etre juste
   * avec la crit qui varierai plus facilement? -> au niveau de l'origin évidemment
   * ex: vict, personne à coté, qui y vont, etc
   * ex: explo personne en face, derrière, etc
   * 
   * Problème évitemment des autres : ça marche pas bien, par exemple dans maze3, en haut à gauche
   * souvent on a 3 agents alignés, celui du milieu peut aller à droite, mais il y va pas
   * car les 2 autres font justes deux vecteurs opposés qui s'annulent…
   */
class BehaviourImpl extends ComposedBehaviour implements RobotVisu {
	
	val logger = LoggerFactory.getLogger("agent")
	
	val boolean withVictim
	
	new(boolean withVictim) {
		this.withVictim = withVictim
	}
	
	override protected make_d() {
		new DecisionsImpl
	}
	
	override protected make_r() {
		new RepresentationsImpl(withVictim)
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
	
	override move() {
		parts.ap.perceptions.lastMove
	}
	
	override explorables() {
		parts.r.representations.explorables
	}
	
	override areasOnlyFromMe() {
		parts.r.representations.seenAreas
	}
	
	override victimsFromMe() {
		parts.r.representations.consideredVictims
	}
	
	override explorablesFromOthers() {
		parts.r.representations.explorableFromOthers
	}
}
