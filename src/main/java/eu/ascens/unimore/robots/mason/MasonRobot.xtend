package eu.ascens.unimore.robots.mason

import com.vividsolutions.jts.algorithm.Angle
import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.mason.datatypes.RelativeCoordinates
import eu.ascens.unimore.robots.mason.datatypes.SlopeComparator
import eu.ascens.unimore.xtend.macros.Step
import eu.ascens.unimore.xtend.macros.StepCached
import fj.data.List
import org.eclipse.xtext.xbase.lib.Pair
import org.slf4j.LoggerFactory
import rlforj.los.ILosBoard
import rlforj.los.PrecisePermissive
import sim.engine.SimState
import sim.engine.Steppable
import sim.util.Bag
import sim.util.Double2D
import sim.util.Int2D
import sim.util.MutableDouble2D

import static extension eu.ascens.unimore.robots.Utils.*
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

	def void applyMove(RelativeCoordinates to) {
		val s = Math.min(state.speed, to.value.length)
		val newLoc = new Double2D(new MutableDouble2D(to.value).resize(s).addIn(position))
		if (state.isInMaze(newLoc) && !state.isWall(newLoc)) {
			// TODO what if there is already an agent in it?
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
	
	def getVisibleWalls() {
		surroundings.wallCoords
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
		"@" + RelativeCoordinates.of(new Double2D(position))
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
	
	// this will gather pairs of Vectors that 
	// satisfies f and that are next to each other in terms of angle
	// in the counter-clockwise direction
	// in particular it handles the special case of the last and the first
	// when they are around the 0 angle
	// for the special of one element, consider the cone around it (of arc ~= 1)
	def <B,C> gathers(List<Pair<Double2D, B>> in, (Pair<Double2D, B>,Pair<Double2D, B>) => Boolean pred, (Pair<Double2D, B>,Pair<Double2D, B>) => C tr) {
		
		if (in.empty) {
			return List.nil
		}
		
		// length == 1
		if (in.tail.empty) {
			val h = in.head
			return List.single(tr.apply(h,h))
		}
		
		val sorted = in.sort(SlopeComparator.ORD_D2D.comap([Pair<Double2D, B> p| p.key]))
		
		// this is mutable, careful!
		var res = List.Buffer.empty
		var Pair<Double2D, B> prev = null
		
		// length == 2
		val length2 = sorted.tail.tail.empty
		if (length2) {
			prev = sorted.tail.head
		} else {
			for (wc: sorted) {
				if (prev != null && pred.apply(prev,wc)) {
					res += tr.apply(prev,wc)
				}
				prev = wc
			}
		}
		
		if (prev != null) {
			// prev is the last
			val h = sorted.head
			if (pred.apply(prev,h)) {
				val pa = prev.key.angle
				val ca = h.key.angle
				if (pa < 0 && pa > -Angle.PI_OVER_2 && ca >= 0 && ca < Angle.PI_OVER_2) {
					res += tr.apply(prev,h)
				} else if (length2) {
					res += tr.apply(h,prev)
				}
			}
		}
		
		res.toList
	}
	
	private def relativeDiscretizedPosition(Int2D p) {
		new Double2D(p).subtract(new Double2D(position.x as int, position.y as int))
	}
	
	@StepCached(warnNoStep = false)
	def getSensorReadings() {
		
		val dircones = RelativeCoordinates.SENSORS_DIRECTIONS_CONES
		
		// we compute the relative vector
		// from a discretized version of the bot position
		// in order to have position coherent with the positions of the walls
		val wcs = wallCoords.map[it.relativeDiscretizedPosition -> it]

		// build small cones 
		val wcones = wcs.gathers([p1, p2|
			me.state.touches(p1.value,p2.value)
		], [p1,p2|
			// TODO optimize that a bit, see behaviour or Utils…
			val rotRight = new Double2D(p1.key.y, -p1.key.x).resize(1.0/2.0)
			val rotLeft = new Double2D(-p2.key.y, p2.key.x).resize(1.0/2.0)
			p1.key.add(rotRight) -> p2.key.add(rotLeft)
		])
		
		dircones.map[d|
			val fromD = d.cone.key
			val toD = d.cone.value
			// TODO would be better if we had the cones which cover a space where there is no wall?
			// instead of covering no wall at all?
			val ws = wcones.filter[
				fromD.between(it) || toD.between(it) // sides of d touch walls
				|| it.key.between(d.cone) || it.value.between(d.cone) // exist walls inside d
			]
			val l = if (ws.empty) {
				Constants.VISION_RANGE
			} else {
				// the mean of the distances of the wall in this cone
				ws.foldLeft([s,e|s+e.key.length+e.value.length], 0.0)/(ws.length*2)
			}
			d.multiply(l) -> !ws.empty
		]
	}
	
	@StepCached(warnNoStep = false)
	def getVisibleVictims() {
		victims.map[b|
			RelativeCoordinates.of(new Double2D(b).relativeVectorFor)
		]
	}
	
	@StepCached(warnNoStep = false)
	def getRBVisibleBotsWithCoordinate() {
		foundBots.remove(me)
		List.iterableList(foundBots as Iterable<MasonRobot>).map[b|
			b -> RelativeCoordinates.of(new Double2D(b.position).relativeVectorFor)
		]
	}
}