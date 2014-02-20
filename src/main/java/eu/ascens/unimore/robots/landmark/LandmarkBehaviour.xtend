package eu.ascens.unimore.robots.landmark

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import eu.ascens.unimore.xtend.macros.StepCached
import sim.util.Double2D

import static eu.ascens.unimore.robots.landmark.State.*

import static extension eu.ascens.unimore.xtend.extensions.MasonExtensions.*

class LandmarkBehaviour extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected start() {
		super.start()
		setState(WANDER)
	}
	
	var State state
	var int counter
	
	private def setState(State state) {
		this.state = state
		this.counter = 0
	}
	
	@StepCached
	def step() {
		switch state {
			case WANDER: wander_in_nest()
			case EXIT: exit_nest()
		}
	}
	
	def exit_nest() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	private def void wander_in_nest() {
		if (shouldExit) {
			switch_to_exiting()
		} else if (requires.see.outOfNest) {
			setState(State.FIRST)
		} else {
			val repulsion = repulsion_vector
			if (repulsion.x*repulsion.x+repulsion.y*repulsion.y > 0.001) {
				doMove(repulsion)
			} else {
				doMove(lastMove)
			}
		}
	}
	
	var lastMove = new Double2D(5,5)
	def doMove(Double2D dir) {
		requires.move.setNextMove(dir)
		lastMove = dir
	}
	
	def shouldExit() {
		getRBs.exists[
			switch it.state {
				case EXIT: true
				case TEMPORARY: true
				case FIRST: true
				case STABLE: true
				case VICTIM: true
				default: false
			}
		]
	}
	
	def repulsion_vector() {
		val v = requires.see.sensorReadings
			.map[dir]
			.foldLeft1([a,b|a+b])
		(v/requires.see.sensorReadings.length).negate
	}
	
	@Cached
	private def getRBs() {
		requires.see.RBVisibleRobots.bind[message.toList.map[it as RBData]]
	}
	
	private def void switch_to_exiting() {
		setState(EXIT)
		requires.rbPublish.push(new RBDataExiting(Double.POSITIVE_INFINITY))
	}
	
	override choice() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override move() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override visibleBots() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override explorables() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override victimsFromMe() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override areasOnlyFromMe() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override explorablesFromOthers() {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
}