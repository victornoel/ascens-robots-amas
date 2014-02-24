package eu.ascens.unimore.robots.mason

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.RequirementsConstants
import eu.ascens.unimore.robots.UIConstants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.SeenVictim
import eu.ascens.unimore.robots.geometry.Radiangle
import java.awt.Color
import java.awt.Font
import java.awt.Graphics2D
import java.awt.geom.AffineTransform
import java.awt.geom.Point2D
import java.util.List
import javax.swing.JFrame
import sim.display.Controller
import sim.display.Display2D
import sim.display.GUIState
import sim.engine.Schedule
import sim.engine.SimState
import sim.engine.Steppable
import sim.field.continuous.Continuous2D
import sim.field.grid.IntGrid2D
import sim.portrayal.DrawInfo2D
import sim.portrayal.FieldPortrayal2D
import sim.portrayal.continuous.ContinuousPortrayal2D
import sim.portrayal.grid.FastValueGridPortrayal2D
import sim.portrayal.simple.OvalPortrayal2D
import sim.util.Double2D
import sim.util.Int2D
import sim.util.TableLoader
import sim.util.gui.SimpleColorMap

import static eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

import static extension fr.irit.smac.lib.contrib.xtend.JavaExtensions.*

@Data class InitialisationParameters {
	
	val double radioRange
	val double wallRange
	val double victimRange
	val double proximityBotRange
	val double speed
	val double rbRange
	val int nbProximityWallSensors
	val String map
	val long seed
	val int nbBots
	val int nbVictims
	val int minBotsPerVictim
	val int maxBotsPerVictim
	val () => Behaviour newBehaviour
	
	@Cached
	def fj.data.List<Pair<Double2D, Pair<Double2D, Double2D>>> sensorDirectionCones() {
		Radiangle.buildCones(nbProximityWallSensors).map[
			val cone = it.key.toNormalizedVector -> it.value.toNormalizedVector
			middleAngledVector(cone.key, cone.value) -> cone
		].sort(ORD_D2D.comap[key]) // sort evaluates
	}
} 

abstract class AscensSimState extends SimState {

	var IntGrid2D maze
	def getMaze() { maze }
	var Continuous2D agents
	def getAgents() { agents }
	var Continuous2D victims
	def getVictims() { victims }
	
	@Property val InitialisationParameters parameters
	@Property var String map
	
	val List<Int2D> availStartingAreas = newArrayList()
	val List<Int2D> availVictimAreas = newArrayList()
	
	new(InitialisationParameters parameters) {
		super(parameters.seed)
		this._parameters = parameters
		this._map = parameters.map
	}

	abstract def void populate()

	override start() {

		super.start()
		
		maze = new IntGrid2D(0, 0)
		
		val grid = TableLoader.loadPNGFile(this.class.getResourceAsStream("/"+map+".png"))
		maze.setTo(grid)
		
		availStartingAreas.clear
		for(i: 0..<maze.width) {
			for(j: 0..<maze.height) {
				if (maze.get(i,j) == 2) {
					availStartingAreas += new Int2D(i,j)
				}
			}
		}
		
		availVictimAreas.clear
		for(i: 0..<maze.width) {
			for(j: 0..<maze.height) {
				if (maze.get(i,j) == 1) {
					availVictimAreas += new Int2D(i,j)
				}
			}
		}
		
		agents = new Continuous2D(1, maze.width, maze.height)
		victims = new Continuous2D(1, maze.width, maze.height)
		
		var nbCreated = 0
		try {
			for (i : 1..this.parameters.nbVictims) {
				addVictim
				nbCreated = i
			}
		} catch (NoVictimAreaAvailable e) {
			println("no more victim area available, created " + nbCreated + " victims.")
		}

		populate()
	}
	
	override finish() {
		maze = null
		agents = null
	}
	
	def isInNest(Double2D loc) {
		isInNest(loc.x as int, loc.y as int)
	}
	
	def isInNest(int x, int y) {
		maze.get(x, y) == 2
	}
	
	def isInMaze(Double2D loc) {
		isInMaze(loc.x as int, loc.y as int)
	}
	
	def isInMaze(Int2D loc) {
		isInMaze(loc.x, loc.y)
	}
	
	def isInMaze(int x, int y) {
		maze.width > x && maze.height > y && y >= 0 && x >= 0
	}

	def isWall(Double2D loc) {
		isWall(loc.x as int, loc.y as int)
	}

	def isWall(Int2D loc) {
		isWall(loc.x, loc.y)
	}

	def isWall(int x, int y) {
		maze.get(x, y) == 0
	}
	
	def addVictim() {
		if (!availVictimAreas.empty) {
			val iPos = availVictimAreas.remove(random.nextInt(availVictimAreas.size))
			val pos = new Double2D(iPos.x+0.5, iPos.y+0.5)
			val nbBots = parameters.minBotsPerVictim + random.nextInt(parameters.maxBotsPerVictim-parameters.minBotsPerVictim)
			victims.setObjectLocation(new Victim(pos, nbBots), pos)
		} else {
			throw new NoVictimAreaAvailable
		}
	}
	
	def add(Steppable r) {
		if (!availStartingAreas.empty) {
			val iPos = availStartingAreas.remove(random.nextInt(availStartingAreas.size))
			val pos = new Double2D(iPos.x+0.5, iPos.y+0.5)
			agents.setObjectLocation(r, pos)
			schedule.scheduleRepeating(Schedule.EPOCH, 0, r, 1)
			pos
		} else {
			throw new NoStartingAreaAvailable
		}
	}
}

class NoStartingAreaAvailable extends RuntimeException {}
class NoVictimAreaAvailable extends RuntimeException {}

class ModelProperties {
	
	val AscensSimState state
	
	new(AscensSimState state) {
		this.state = state
		setMap(UIConstants.MAZES.indexOf(state.map))
	}
	
	def setMap(int map) {
		_map = map
		state.setMap(UIConstants.MAZES.get(map))
	}
	
	@Property int map
	def Object domMap() {
		UIConstants.MAZES
	}
	@Property boolean showSensorReadings = false
	@Property boolean showSensorReadingsForAll = false
	@Property boolean showWalls = false
	@Property boolean showWallsForAlls = false
	@Property boolean showVisible = false
	@Property boolean showVisibleForAlls = false
	@Property boolean showAreasOnlyFromMe = false
	@Property boolean showAreasOnlyFromMeForAll = false
	@Property boolean showVictimsFromMe = false
	@Property boolean showVictimsFromMeForAll = false
	@Property boolean showExplorableFromOthers = false
	@Property boolean showExplorableFromOthersForAll = false
	@Property boolean showExplorable = false
	@Property boolean showExplorableForAll = false
	@Property boolean showVisibleBotsAndVictims = false
	@Property boolean showWhoFollowsWhoForAll = false
	@Property boolean showWhoFollowsWho = false
}

class AscensGUIState extends GUIState {

	// initialised in start
	var FastValueGridPortrayal2D mazePortrayal
	var ContinuousPortrayal2D agentsPortrayal
	var ContinuousPortrayal2D victimsPortrayal
	
	// initialised in init
	var Display2D display
	var JFrame displayFrame

	val ModelProperties properties
	
	new(AscensSimState state) {
		super(state)
		properties = new ModelProperties(state)
	}
	
	override getSimulationInspectedObject() {
		properties
	}

	def setupPortrayals() {
		val state = state as AscensSimState
		
		agentsPortrayal.setPortrayalForClass(AscensMasonImpl.RobotImpl.MyMasonRobot, new BotPortrayal2D(agentsPortrayal, properties))
		victimsPortrayal.setPortrayalForClass(Victim, new VictimPortrayal2D(victimsPortrayal, state))
		// set up the maze portrayal
		mazePortrayal.setMap(new SimpleColorMap(0,3,Color.LIGHT_GRAY,Color.WHITE))

		// attach the portrayals
		display.detatchAll
		display.attach(mazePortrayal, "Maze")
		display.attach(victimsPortrayal, "Victims")
		display.attach(agentsPortrayal, "Agents")
		display.setBackdrop(Color.white)
		
		// reschedule the displayer
		display.reset()

		// redraw the display
		display.repaint()
	}

	override start() {
		super.start()
		
		val state = (state as AscensSimState)
		
		mazePortrayal = new FastValueGridPortrayal2D()
		agentsPortrayal = new ContinuousPortrayal2D()
		victimsPortrayal = new ContinuousPortrayal2D()
		
		agentsPortrayal.setField(state.agents)
		mazePortrayal.setField(state.maze)
		victimsPortrayal.setField(state.victims)
		
		setupPortrayals()
	}

	// TODO better
	override init(Controller controller) {
		super.init(controller)

		// Make the Display2D.  We'll have it display stuff later
		display = new Display2D(800, 800, this)

		// register the frame so it appears in the "Display" list
		displayFrame = display.createFrame();
		controller.registerFrame(displayFrame);
		displayFrame.setVisible(true);
	}

	override quit() {
		super.quit()

		// disposing the displayFrame automatically calls quit() on the display,
		// so we don't need to do so ourselves here.
		if(displayFrame != null) displayFrame.dispose()
		displayFrame = null // let gc
		display = null // let gc
	}

	override load(SimState state) {
		super.load(state)

		// we now have new grids.  Set up the portrayals to reflect that
		setupPortrayals()
	}
}

class VictimPortrayal2D extends OvalPortrayal2D {
	
	val FieldPortrayal2D fieldPortrayal
	val AscensSimState state
	
	new(FieldPortrayal2D fieldPortrayal, AscensSimState state) {
		super(Color.RED, 1.5, true)
		this.fieldPortrayal = fieldPortrayal
		this.state = state
	}
	
	override draw(Object object, Graphics2D graphics, DrawInfo2D info) {
		switch object {
			Victim: {
				val agentsHere = state.agents.getNeighborsExactlyWithinDistance(object.position, RequirementsConstants.CONSIDERED_NEXT_TO_VICTIM_DISTANCE)
				if (agentsHere!= null && agentsHere.size >= object.nbBotNeeded) {
					this.paint = Color.GREEN
				} else {
					this.paint = Color.RED
				}
			}
		}
		super.draw(object, graphics, info)
	}
}

class BotPortrayal2D extends OvalPortrayal2D {
	
	val FieldPortrayal2D fieldPortrayal
	val ModelProperties properties
	
	new(FieldPortrayal2D fieldPortrayal, ModelProperties properties) {
		super(Color.DARK_GRAY, 1.0, true)
		this.fieldPortrayal = fieldPortrayal
		this.properties = properties
	}
	
	override draw(Object object, Graphics2D graphics, DrawInfo2D info) {
		switch object {
			AscensMasonImpl.RobotImpl.MyMasonRobot: {
				val w = info.draw.width as int
				val h = info.draw.height as int
				val botPos = fieldPortrayal.getObjectLocation(object, info.gui) as Double2D
				val botFPos = fieldPortrayal.getRelativeObjectPosition(botPos, botPos, info)
				
				if (info.selected) {
					this.paint = Color.MAGENTA
				} else {
					this.paint = Color.DARK_GRAY
				}
				
				if (properties.showWallsForAlls || (info.selected && properties.showWalls)) {
					for (wc: object.surroundings.wallCoords.map[new Double2D(it)]) {
						val wp = fieldPortrayal.getRelativeObjectPosition(wc, botPos, info)
						graphics.setPaint(Color.RED)
						graphics.fillRect(wp.x as int, wp.y as int, w, h)
					}
					for (wc: object.surroundings.wallCones) {
						val sloc1 = wc.key.add(botPos)
						val spos1 = fieldPortrayal.getRelativeObjectPosition(sloc1, botPos, info)
						val sloc2 = wc.value.add(botPos)
						val spos2 = fieldPortrayal.getRelativeObjectPosition(sloc2, botPos, info)
						graphics.setPaint(Color.BLUE)
						graphics.drawLine(spos1.x as int, spos1.y as int, spos2.x as int, spos2.y as int)
					}
				}
				
				if (properties.showVisibleForAlls || (info.selected && properties.showVisible)) {
					for (wc: object.surroundings.noWallCoords.map[new Double2D(it)]) {
						val wp = fieldPortrayal.getRelativeObjectPosition(wc, botPos, info)
						graphics.setPaint(Color.GREEN)
						graphics.fillRect(wp.x as int, wp.y as int, w, h)
					}
				}
				
				if (properties.showExplorableFromOthersForAll || (info.selected && properties.showExplorableFromOthers)) {
					for(c: object.visu.explorablesFromOthers) {
						graphics.printExplorable(c, botPos, botFPos, info)
					}
				}
				
				if (properties.showAreasOnlyFromMeForAll || (info.selected && properties.showAreasOnlyFromMe)) {
					for(c: object.visu.areasOnlyFromMe) {
						graphics.printExplorable(c, botPos, botFPos, info)
					}
				}
				
				if (properties.showVictimsFromMeForAll || (info.selected && properties.showVictimsFromMe)) {
					for(c: object.visu.victimsFromMe) {
						graphics.printVisibleVictim(c, botPos, botFPos, info)
					}
				}
				
				
				if (properties.showExplorableForAll || (info.selected && properties.showExplorable)) {
					for(c: object.visu.explorables) {
						graphics.printExplorable(c, botPos, botFPos, info)
					}
					if (object.visu.choice != null) {
						val sloc = object.visu.choice.direction.add(botPos)
						val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
						graphics.setPaint(Color.CYAN)
						graphics.fillOval(spos.x as int, spos.y as int, w/2, h/2)
					}
					val sloc2 = object.visu.move.add(botPos)
					val spos2 = fieldPortrayal.getRelativeObjectPosition(sloc2, botPos, info)
					graphics.setPaint(Color.MAGENTA)
					graphics.fillOval(spos2.x as int, spos2.y as int, w/2, h/2)
				}
				
				if (properties.showSensorReadingsForAll || (info.selected && properties.showSensorReadings)) {
					for(p: object.sensorReadings) {
						// get absolute position
						val sloc = p.dir.add(botPos)
						if (p.hasWall) {
							graphics.setPaint(Color.PINK)
						} else if (p.hasBot) {
							graphics.setPaint(Color.GREEN)
						} else {
							graphics.setPaint(Color.MAGENTA)
						}
						val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
						graphics.drawArrow(botFPos.x as int, botFPos.y as int, spos.x as int, spos.y as int)
						//graphics.fillOval(spos.x as int, spos.y as int, w/2, h/2)
					}
				}
				
				if (properties.showVisibleBotsAndVictims && info.selected) {
					val vis = object.surroundings.RBVisibleBotsWithCoordinate.map[value]
								+ object.surroundings.visibleVictims.map[dir]
					for(b: vis) {
						val sloc = b.add(botPos)
						val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
						graphics.setPaint(Color.BLUE)
						graphics.drawOval((spos.x - (w+2)/2) as int, (spos.y - (h+2)/2) as int, w+2, h+2)
					}
				}
				
				if (properties.showWhoFollowsWhoForAll ||(properties.showWhoFollowsWho && info.selected)) {
					switch c: object.visu.choice {
						Explorable case c.via != null: {
							val sloc1 = c.via.add(botPos)
							val spos1 = fieldPortrayal.getRelativeObjectPosition(sloc1, botPos, info)
							graphics.setPaint(Color.BLUE)
							graphics.drawArrow(botFPos.x as int, botFPos.y as int, spos1.x as int, spos1.y as int)
						}
					}
				}
			}
		}
		
		super.draw(object, graphics, info)
	}
	
	def printVisibleVictim(Graphics2D graphics, SeenVictim v, Double2D botPos, Point2D.Double botFPos, DrawInfo2D info) {
		val sloc = v.direction.add(botPos)
		val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
		graphics.setPaint(Color.GREEN)
		graphics.drawArrow(botFPos.x as int, botFPos.y as int, spos.x as int, spos.y as int)
		val toPrint = ""+v.howMuch
		
		val lx = botFPos.x*0.2+spos.x*0.8
		val ly = botFPos.y*0.2+spos.y*0.8
		
		printLabel(toPrint, graphics, info, lx as int, ly as int)
	}
	
	def printExplorable(Graphics2D graphics, Explorable e, Double2D botPos, Point2D.Double botFPos, DrawInfo2D info) {
		val sloc = e.direction.add(botPos)
		val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
		graphics.setPaint(Color.GREEN)
		graphics.drawArrow(botFPos.x as int, botFPos.y as int, spos.x as int, spos.y as int)
		val toPrint = e.criticality.toShortString(2)
		
		val lx = botFPos.x*0.2+spos.x*0.8
		val ly = botFPos.y*0.2+spos.y*0.8
		
		printLabel(toPrint, graphics, info, lx as int, ly as int)
	}
	
	val static FONT = new Font("SansSerif",Font.PLAIN, 10)
	def static printLabel(String s, Graphics2D graphics, DrawInfo2D info, int ox, int oy) {
		val x = (ox + 0 * info.draw.width + 0) as int
        val y = (oy + 0.5 * info.draw.height + 10) as int
        graphics.setPaint(Color.BLACK)
        graphics.setFont(FONT)
        
        graphics.drawString(s,x,y);
	}
	
	val static ARR_SIZE = 5

	def static drawArrow(Graphics2D g1, int x1, int y1, int x2, int y2) {
		val g = g1.create as Graphics2D
		
		val dx = x2 - x1
		val dy = y2 - y1
		val angle = Math.atan2(dy, dx);
		val len = Math.sqrt(dx * dx + dy * dy) as int
		val at = AffineTransform.getTranslateInstance(x1, y1)
		at.concatenate(AffineTransform.getRotateInstance(angle))
		g.transform(at)

		// Draw horizontal arrow starting in (0, 0)
		g.drawLine(0, 0, len, 0)
		g.fillPolygon(#[len, len - ARR_SIZE, len - ARR_SIZE, len],
			#[0, -ARR_SIZE, ARR_SIZE, 0], 4)
	}
	
}