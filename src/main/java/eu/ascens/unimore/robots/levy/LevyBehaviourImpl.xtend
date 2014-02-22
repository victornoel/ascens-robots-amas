package eu.ascens.unimore.robots.levy

import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.geometry.GeometryExtensions
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

class LevyBehaviourImpl extends Behaviour implements RobotVisu {
	
	override protected make_step() {
		[|step]
	}
	
	override protected make_visu() {
		this
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
	
	private var Double2D currentDir
	private var double alpha
	private var double accumulator
	
	private def step() {
		if (currentDir == null || shouldChange) {
			currentDir = randomDirection()
			alpha = requires.random.pull.nextDouble
			accumulator = 0
		}
		if (!bump) {
			requires.move.setNextMove(currentDir)
			accumulator = accumulator + alpha
		}
	}
	
	def bump() {
		requires.see.sensorReadings.exists[
			((hasWall && dir.lengthSq < 2)
			|| (hasBot && dir.lengthSq < 1))
			&& currentDir.between(cone)
		]
	}
	
	def shouldChange() {
		accumulator > 1
		|| bump
	}
	
	def randomDirection() {
		GeometryExtensions.SENSORS_DIRECTIONS_CONES
			.index(requires.random.pull.nextInt(Constants.NB_WALL_SENSORS))
			.key
	}
	
}