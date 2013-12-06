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
	package val MutableDouble2D position
	package val AscensSimState state

	new(AscensSimState state, String id) {
		this.state = state
		this.id = id
		this.position = new MutableDouble2D(this.state.add(this))
	}
	
	@Step
	override step(SimState state) {
	}

	def void applyMove(Double2D to) {
		val s = Math.min(state.speed, to.length)
		val newLoc = new Double2D(new MutableDouble2D(to).resize(s).addIn(position))
		if (state.isInMaze(newLoc) && !state.isWall(newLoc)) {
			position.setTo(newLoc)
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
		//getBotsAroundMe(state.radioRange).toList
	}
	
	def getVisibleVictims() {
		surroundings.visibleVictims
	}
	
	@StepCached
	def surroundings() {
		val discrPos = new Int2D(position.x as int, position.y as int)
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
		"@" + new Double2D(position).toShortString
	}
}

class Surroundings implements ILosBoard {
	
	val MasonRobot me
	val Double2D position
	
	new(MasonRobot me) {
		this.me = me
		this.position = new Double2D(me.position)
	}
	
	override contains(int x, int y) {
		me.state.isInMaze(x,y)
	}
	
	override isObstacle(int x, int y) {
		me.state.isWall(x,y)
	}
	
	def getRelativeVectorFor(Double2D p) {
		p.subtract(position);
	}
	
	val foundBots = new Bag
	package var List<Int2D> wallCoords = List.nil
	package var List<Int2D> victims = List.nil
	package var List<Int2D> noWallCoords = List.nil
	
	override visit(int x, int y) {
		val ob = isObstacle(x, y)
		val pos = new Int2D(x,y)
		val dist = position.distance(pos)
		
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
//		// assumption is that blocks are 1m wide
//		var ys = if (wall.x < meD.x) -1
//				else if (wall.x > meD.x) 1
//				else 0
//		
//		var xs = if (wall.y < meD.y) 1
//				else if (wall.y > meD.y) -1
//				else 0
//		
//		if (xs == 0 && ys == 0) {
//			// can't happen
//			throw new RuntimeException("impossible, bot would be inside a wall.")
//		}

		// correspond to the center of the wall from double2d bot position pov
		val wx = wall.x + 0.5
		val wy = wall.y + 0.5
//		
//		val from = new Double2D(wx - 0.5*xs, wy - 0.5*ys)
//		val to = new Double2D(wx + 0.5*xs, wy + 0.5*ys)

		if (wall.x < meD.x) {
			if (wall.y < meD.y) {
				// TODO relative!
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
			// these two are not covered by the previous implemention
			if (wall.y < meD.y) {
				new Double2D(wx - 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy + 0.5)
			} else if (wall.y > meD.y) {
				new Double2D(wx + 0.5, wy - 0.5)-> new Double2D(wx - 0.5, wy - 0.5) 
			} else {
				// can't happen!
				throw new RuntimeException("impossible, bot would be inside a wall.")
			}
		}
		
//		from -> to
	}
	
	@StepCached(warnNoStep = false)
	def wallCones() {
		val meD = me.state.agents.discretize(position)
		wallCoords.map[coneForWallFromMe(meD)].map[key.relativeVectorFor -> value.relativeVectorFor]
	}
	
	@StepCached(warnNoStep = false)
	def getSensorReadings() {
		
		// we compute the relative vector
		// from a discretized version of the bot position
		// in order to have position coherent with the positions of the walls
		//val wcs = wallCoords.map[it.relativeDiscretizedPosition -> it]
		
		// build small cones 
		val wcones = wallCones//.map[key.relativeVectorFor -> value.relativeVectorFor]
		
		SENSORS_DIRECTIONS_CONES.map[d|
			val fromD = d.value.key
			val toD = d.value.value
			// TODO would be better if we had the cones which cover a space where there is no wall?
			// instead of covering no wall at all?
			val ws = wcones.filter[
				fromD.between(it) || toD.between(it) // sides of d touch walls
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
		victims.map[b|
			new Double2D(b).relativeVectorFor
		]
	}
	
	@StepCached(warnNoStep = false)
	def getRBVisibleBotsWithCoordinate() {
		foundBots.remove(me)
		List.iterableList(foundBots as Iterable<MasonRobot>).map[b|
			b -> new Double2D(b.position).relativeVectorFor
		]
	}
}