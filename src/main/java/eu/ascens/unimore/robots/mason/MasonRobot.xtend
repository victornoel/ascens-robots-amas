package eu.ascens.unimore.robots.mason

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.mason.datatypes.SensorReading
import fj.Ord
import fj.data.List
import fr.irit.smac.lib.contrib.xtend.macros.StepCached
import org.slf4j.LoggerFactory
import rlforj.los.ILosBoard
import rlforj.los.PrecisePermissive
import sim.engine.SimState
import sim.engine.Steppable
import sim.util.Double2D
import sim.util.Int2D
import sim.util.MutableDouble2D

import static eu.ascens.unimore.robots.geometry.GeometryExtensions.*

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*
import static extension fr.irit.smac.lib.contrib.fj.xtend.FunctionalJavaExtensions.*

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
	
	@StepCached
	override void step(SimState state) {
	}

	def void applyMove(Double2D to) {
		val s = Math.min(state.parameters.speed, to.length)
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
			b !== this && b.position.distance(position) < state.parameters.radioRange
		]
	}
	
	def getVisibleVictims() {
		surroundings.visibleVictims
	}
	
	@Cached
	def Surroundings surroundings() {
		val discrPos = state.agents.discretize(position)
		// TODO clean that, that's not very good, there is other range also...
		val dist = Math.max(state.parameters.rbRange, state.parameters.wallRange) as int
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
	
	def isOutOfNest() {
		!state.isInNest(position)
	}

	override toString() {
		"@" + position.toShortString(2)
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
	
	var List<MasonRobot> foundBots = List.nil
	package var List<Int2D> wallCoords = List.nil
	package var List<Int2D> victims = List.nil
	package var List<Int2D> noWallCoords = List.nil
	package var List<Double2D> proximityBots = List.nil
	
	override visit(int x, int y) {
		val ob = isObstacle(x, y)
		val pos = new Int2D(x,y)
		val dist = me.position.distance(pos)
		
		if (!ob && dist < me.state.parameters.rbRange) {
			val r = me.state.agents.getObjectsAtDiscretizedLocation(pos)
			if (r != null) {
				for (b: r.filter(MasonRobot)) {
					if (b !== me) {
						val realDist = b.position.distance(me.position)
						if (realDist < me.state.parameters.rbRange) {
							foundBots = b + foundBots
						}
						if (realDist < me.state.parameters.proximityBotRange) {
							proximityBots = b.position.relativeVectorFor + proximityBots
						}
					}
				}
			}
		}
		if (!ob && dist < me.state.parameters.victimRange) {
			if (me.state.isVictim(x,y)) {
				victims = pos + victims
			}
		}
		if (dist < me.state.parameters.wallRange) {
			if (ob) {
				wallCoords = pos + wallCoords
			} else {
				noWallCoords = pos + noWallCoords
			}
		}
	}
	
	private def conesForWallFromMe(Int2D wall, Int2D meD) {
		// correspond to the center of the wall from double2d bot position pov
		val wx = wall.x + 0.5
		val wy = wall.y + 0.5
		
		/*
		 * this compute cones (from left to right in the figure)
		 * of the side of the squares from bot pov
               +--------------+
               | a  | g  | d  |
               |    |    |    |
               |----|----|----|
               | c  | bot| f  |
               |    |    |    |
               |----|----|----|
               | b  | h  | e  |
               |    |    |    |
               +--------------+
		 */
		
		if (wall.x < meD.x) {
			if (wall.y < meD.y) {
				// a
				List.list(
					new Double2D(wx - 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy + 0.5),
					new Double2D(wx + 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy - 0.5)
				)
			} else if (wall.y > meD.y) {
				// b
				List.list(
					new Double2D(wx + 0.5, wy + 0.5)-> new Double2D(wx + 0.5, wy - 0.5),
					new Double2D(wx + 0.5, wy - 0.5)-> new Double2D(wx - 0.5, wy - 0.5)
				) 
			} else {
				// c
				List.list(
					new Double2D(wx + 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy - 0.5)
				)
			}
		} else if (wall.x > meD.x) {
			if (wall.y < meD.y) {
				// d
				List.list(
					new Double2D(wx - 0.5, wy - 0.5) -> new Double2D(wx - 0.5, wy + 0.5),
					new Double2D(wx - 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy + 0.5)
				)
			} else if (wall.y > meD.y) {
				// e
				List.list(
					new Double2D(wx + 0.5, wy - 0.5) -> new Double2D(wx - 0.5, wy - 0.5),
					new Double2D(wx - 0.5, wy - 0.5) -> new Double2D(wx - 0.5, wy + 0.5)
				)
			} else {
				// f
				List.list(
					new Double2D(wx - 0.5, wy - 0.5)-> new Double2D(wx - 0.5, wy + 0.5)
				)
			}
		} else {
			if (wall.y < meD.y) {
				// g
				List.list(
					new Double2D(wx - 0.5, wy + 0.5) -> new Double2D(wx + 0.5, wy + 0.5)
				)
			} else if (wall.y > meD.y) {
				// h
				List.list(
					new Double2D(wx + 0.5, wy - 0.5)-> new Double2D(wx - 0.5, wy - 0.5)
				)
			} else {
				throw new RuntimeException("impossible, bot would be inside a wall.")
			}
		}
	}
	
	@Cached
	def List<Pair<Double2D, Double2D>> wallCones() {
		val meD = me.state.agents.discretize(me.position)
		wallCoords
			.bind[conesForWallFromMe(meD)]
			.map[key.relativeVectorFor -> value.relativeVectorFor]
	}
	
	@Cached
	def List<SensorReading> getSensorReadings() {
		SENSORS_DIRECTIONS_CONES.map[d|
			// bots in this cone
			val pbots = proximityBots.filter[between(d.value)]
			// walls touched by this direction
			val ws = wallCones.filter[d.key.between(it)]
			
			val l = if (pbots.notEmpty) {
				pbots.map[length].minimum(Ord.doubleOrd)
			} else if (ws.notEmpty) {
				// the closest wall in the cone
				// this is kind of ok but not very formal way
				// of computing the length of the middle intersection
				// with the wall
				ws.map[Math.sqrt((key.lengthSq+value.lengthSq)/2)].minimum(Ord.doubleOrd)
			} else {
				me.state.parameters.wallRange
			}
			
			// this could miss some walls being between two of the directions
			// but when we get closer we would see it anyway
			
			val dist = Math.min(me.state.parameters.wallRange, l)
			new SensorReading(d.key*dist, d.value, ws.notEmpty, pbots.notEmpty)
		]
	}
	
	@Cached
	def List<Double2D> getVisibleVictims() {
		victims.map[relativeVectorFor]
	}
	
	@Cached
	def List<Pair<MasonRobot, Double2D>> getRBVisibleBotsWithCoordinate() {
		foundBots.map[b|
			b -> b.position.relativeVectorFor
		]
	}
}