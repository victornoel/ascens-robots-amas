package eu.ascens.unimore.robots.disperse

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.mason.datatypes.Message
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached

class DisperseBehaviourWithTweaks extends DisperseBehaviour {
	
	@StepCached
	override protected void step() {
		super.step()
		if (victimsOfInterest.empty) {
			requires.rbPublish.push(new DisperseMessage(false))
		} else {
			requires.rbPublish.push(new DisperseMessage(true))
		}
	}
	
	@Cached
	override def List<RBEmitter> botsToConsider() {
		requires.see.RBVisibleRobots
		.filter[
			switch m: message.toNull {
				DisperseMessage: !m.onVictim
				default: true
			}
		]
	}
	
}

@Data class DisperseMessage extends Message {
	val boolean onVictim
}