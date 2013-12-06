package eu.ascens.unimore.robots.mason

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import org.slf4j.LoggerFactory
import rlforj.los.ILosBoard
import rlforj.los.PrecisePermissive
import sim.engine.SimState
import sim.engine.Steppable
import sim.util.Bag
import sim.util.Double2D
import sim.util.Int2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static extension eu.ascens.unimore.xtend.extensions.FunctionalJavaExtensions.*

abstract class MasonRobot implements Steppable {

	val logger = LoggerFactory.getLogger("agent");

	package val String id
	package var Double2D position
	package val AscensSimState state

	new(AscensSimState state, String id) {
		this.state = state
		this.id = id
		this.position = this.state.add(this)
	}
	
	@Step
	override step(SimState state) {
	}

	def void applyMove(Double2D to) {
		val s = Math.min(state.speed, to.length)
		val newLoc = new Double2D(new MutableDouble2D(to).resize(s).addIn(position))
		if (state.isInMaze(newLoc) && !state.isWall(newLoc)) {
			position = newLoc
			state.agents.setObjectLocation(this, newLoc);
		} else {
			logger.error("tried to go into a wall: from {} to {}.",position,newLoc)
		}
	}
	
	def getRadioReachableBots() {
		// uses allObjects since the number of bot is limited and the distance is big
		// will be more efficient than getNeighborsWithinDistance
		List.iterableList(state.agents.allObjects as Iterable<MasonRobot>).filter[b|
			b !== this && b.position.distance(position) < state.radioRange
		]
	}
	
	def getVisibleVictims() {
		surroundings.visibleVictims
	}
	
	@StepCached
	def surroundings() {
		val discrPos = state.agents.discretize(position)
		val dist = Math.max(state.rbRange, state.visionRange) as int
		new Surroundings(this) => [s|
			// shadow casting just sucks... this one is symmetric so it's better...
			new PrecisePermissive().visitFieldOfView(s, discrPos.x, discrPos.y, dist)
		]
	}
	
	def getRBVisibleBotsWithCoordinate() {
		surroundings.RBVisibleBotsWithCoordinate
	}
	
	def getSensorReadings() {
		surroundings.sensorReadings
	}

	override toString() {
		"@" + position.toShortString
	}
}

class Surroundings implements ILosBoard {
	
	val MasonRobot me
	
	new(MasonRobot me) {
		this.me = me
	}
	
	override contains(int x, int y) {
		me.state.isInMaze(x,y)
	}
	
	override isObstacle(int x, int y) {
		me.state.isWall(x,y)
	}
	
	def getRelativeVectorFor(Double2D p) {
		p - me.position
	}
	
	def getRelativeVectorFor(Int2D p) {
		new Double2D(p.x+0.5, p.y+0.5).getRelativeVectorFor
	}
	
	val foundBots = new Bag
	package var List<Int2D> wallCoords = List.nil
	package var List<Int2D> victims = List.nil
	package var List<Int2D> noWallCoords = List.nil
	
	override visit(int x, int y) {
		val ob = isObstacle(x, y)
		val pos = new Int2D(x,y)
		val dist = me.position.distance(pos)
		
		if (!ob && dist < me.state.rbRange) {
			val r = me.state.agents.getObjectsAtDiscretizedLocation(pos)
			if (r != null) {
				foundBots.addAll(r)
			}
		}
		if (!ob && dist < me.state.visionRange) {
			if (me.state.isVictim(x,y)) {
				victims = pos + victims
			}
		}
		if (!ob && dist < me.state.visionRange) {
			noWallCoords = pos + noWallCoords
		}
		if (ob && dist < me.state.visionRange) {
			wallCoords = pos + wallCoords
		}
	}
	
	private def coneForWallFromMe(Int2D wall, Int2D meD) {
		// correspond to the center of the wall from double2d bot position pov
		val wx = wall.x + 0.5
		val wy = wall.y + 0.5

		if (wall.x < meD.x) {
			if (wall.y < meD.y) {
				new Double2D(wx - 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy - 0.5) 
			} else if (wall.y > meD.y) {
				new Double2D(wx + 0.5, wy + 0.5)-> new Double2D(wx - 0.5, wy - 0.5) 
			} else {
				new Double2D(wx + 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy - 0.5)
			}
		} else if (wall.x > meD.x) {
			if (wall.y < meD.y) {
				new Double2D(wx - 0.5, wy - 0.5) -> new Double2D(wx + 0.5, wy + 0.5)
			} else if (wall.y > meD.y) {
				new Double2D(wx + 0.5, wy - 0.5) -> new Double2D(wx - 0.5, wy + 0.5)
			} else {
				new Double2D(wx - 0.5, wy - 0.5)-> new Double2D(wx - 0.5, wy + 0.5) 
			}
		} else {
			if (wall.y < meD.y) {
				new Double2D(wx - 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy + 0.5)
			} else if (wall.y > meD.y) {
				new Double2D(wx + 0.5, wy - 0.5)-> new Double2D(wx - 0.5, wy - 0.5) 
			} else {
				throw new RuntimeException("impossible, bot would be inside a wall.")
			}
		}
	}
	
	@StepCached(warnNoStep = false)
	def wallCones() {
		val meD = me.state.agents.discretize(me.position)
		wallCoords.map[
			val r = coneForWallFromMe(meD)
			r.key.relativeVectorFor -> r.value.relativeVectorFor
		]
	}
	
	@StepCached(warnNoStep = false)
	def getSensorReadings() {
		
		SENSORS_DIRECTIONS_CONES.map[d|
			// TODO would be better if we had the cones which cover a space where there is no wall?
			// instead of covering no wall at all?
			val ws = wallCones.filter[
				d.value.key.between(it) || d.value.value.between(it) // sides of d touch walls
				|| it.key.between(d.value) || it.value.between(d.value) // exist walls inside d
			]
			val l = if (ws.empty) {
				Constants.VISION_RANGE
			} else {
				// the mean of the distances of the wall in this cone
				ws.foldLeft([s,e|s+e.key.length+e.value.length], 0.0)/(ws.length*2)
			}
			val dist = Math.min(Constants.VISION_RANGE, l)
			new SensorReading(d.key*dist, d.value, !ws.empty)
		]
	}
	
	@StepCached(warnNoStep = false)
	def getVisibleVictims() {
		victims.map[relativeVectorFor]
	}
	
	@StepCached(warnNoStep = false)
	def getRBVisibleBotsWithCoordinate() {
		foundBots.remove(me)
		List.iterableList(foundBots as Iterable<MasonRobot>).map[b|
			b -> b.position.relativeVectorFor
		]
	}
}