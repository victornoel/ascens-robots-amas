package eu.ascens.unimore.robots.beh

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.beh.datatypes.AgentSig
import eu.ascens.unimore.robots.beh.datatypes.ExplorableMessage
import eu.ascens.unimore.robots.beh.datatypes.ReceivedExplorable
import eu.ascens.unimore.robots.beh.interfaces.IMessagingExtra
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached

import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

class MessagingImpl extends Messaging implements IMessagingExtra {

	override protected make_messaging() {
		this
	}
	
	override protected make_preStep() {
		[|preStep]
	}
	
	var int timestamp = 0
	
	@StepCached
	def void preStep() {
		timestamp = timestamp + 1
	}
	
	@Cached
	override List<ReceivedExplorable> explorationMessages() {
		requires.perceptions.visibleRobots.map[vb|
			switch vb.message {
				case vb.message.isSome && vb.coord.lengthSq > 0: {
					switch m: vb.message.some(){
						ExplorableMessage: m.worthExplorable.map[
							new ReceivedExplorable(vb, it)
						]
						default: List.nil
					}
				}
				default: List.nil
			}
		].flatten
	}
	
	override currentSig() {
		new AgentSig(requires.perceptions.myId, timestamp)
	}
	
}