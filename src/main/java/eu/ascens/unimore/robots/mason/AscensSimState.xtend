package eu.ascens.unimore.robots.mason

import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.UIConstants
import eu.ascens.unimore.robots.geometry.Radiangle
import eu.ascens.unimore.robots.mason.datatypes.Stats
import java.awt.Color
import java.util.List
import javax.swing.JFrame
import sim.display.Controller
import sim.display.Display2D
import sim.display.GUIState
import sim.engine.Schedule
import sim.engine.SimState
import sim.field.continuous.Continuous2D
import sim.field.grid.IntGrid2D
import sim.portrayal.continuous.ContinuousPortrayal2D
import sim.portrayal.grid.FastValueGridPortrayal2D
import sim.util.Double2D
import sim.util.Int2D
import sim.util.TableLoader
import sim.util.gui.SimpleColorMap

import static eu.ascens.unimore.robots.geometry.GeometryExtensions.*
import static fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

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
	var IntGrid2D mazeOverlay
	def getMazeOverlay() { mazeOverlay }
	var Continuous2D agents
	def getAgents() { agents }
	
	@Property val InitialisationParameters parameters
	@Property var String map
	
	val List<Int2D> availStartingAreas = newArrayList
	val List<Int2D> availVictimAreas = newArrayList
	val List<Victim> victims = newArrayList
	var int[][] areasToExplore
	var int nbAreasToExplore
	
	new(InitialisationParameters parameters) {
		super(parameters.seed)
		this._parameters = parameters
		this._map = parameters.map
	}

	abstract def void populate()

	override start() {
		super.start()
		
		maze = new IntGrid2D(0, 0)
		maze.setTo(TableLoader.loadPNGFile(this.class.getResourceAsStream("/"+map+".png")))
		
		mazeOverlay = new IntGrid2D(maze.width, maze.height)
		mazeOverlay.setTo(0)
		
		nbAreasToExplore = 0
		for(i: 0..<maze.width) {
			for(j: 0..<maze.height) {
				val type = maze.get(i,j)
				val iPos = new Int2D(i,j)
				if (type == 2) {
					availStartingAreas += iPos
				}
				if (type == 1) {
					availVictimAreas += iPos
				}
				if (type == 1 || type == 2 || type == 3) {
					nbAreasToExplore = nbAreasToExplore + 1
				}
			}
		}
		
		agents = new Continuous2D(1, maze.width, maze.height)
		
		try {
			for (i : 1..this.parameters.nbVictims) {
				victims += new Victim(this)
			}
		} catch (NoVictimAreaAvailable e) {
			println("no more victim area available, created " + victims.size + " victims.")
		}
		
		populate()
	}
	
	override finish() {
		maze = null
		mazeOverlay = null
		agents = null
		victims.clear
		availStartingAreas.clear
		availVictimAreas.clear
		nbAreasToExplore = 0
		areasToExplore = null
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
	
	def add(MasonRobot r) {
		val pos = addOrThrow(r, availStartingAreas, new NoStartingAreaAvailable)
		schedule.scheduleRepeating(Schedule.EPOCH, 0, r, 1)
		pos
	}
	
	def add(Victim v) {
		addOrThrow(v, availVictimAreas, new NoVictimAreaAvailable)
	}
	
	def addOrThrow(Object o, List<Int2D> availablePositions, RuntimeException exception) {
		if (!availablePositions.empty) {
			val iPos = availablePositions.remove(random.nextInt(availablePositions.size))
			val pos = new Double2D(iPos.x+0.5, iPos.y+0.5)
			agents.setObjectLocation(o, pos)
			pos
		} else {
			throw exception
		}
	}
	
	def getCurrentStats() {
		var allSecured = true
		var nbSecured = 0
		var nbDiscovered = 0
		for(v: victims) {
			if (v.secured) {
				nbSecured = nbSecured + 1
			} else {
				allSecured = false
			}
			if (v.discovered) {
				nbDiscovered = nbDiscovered + 1
			}
		}
		
		var nbExplored = 0
		for(i: 0..<mazeOverlay.width) {
			for(j: 0..<mazeOverlay.height) {
				if (mazeOverlay.get(i,j) == 1) {
					nbExplored = nbExplored + 1
				}
			}
		}
		
		new Stats(
			schedule.steps,
			allSecured,
			nbSecured,
			nbDiscovered,
			(((nbExplored as double)/(nbAreasToExplore as double))*100) as int
		)
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
	var FastValueGridPortrayal2D mazeOverlayPortrayal
	var ContinuousPortrayal2D agentsPortrayal
	
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
		agentsPortrayal.setPortrayalForClass(Victim, new VictimPortrayal2D(agentsPortrayal, state))
		mazePortrayal.setMap(new SimpleColorMap(#[
			Color.BLACK,
			Color.WHITE,
			Color.LIGHT_GRAY,
			Color.WHITE
		]))
		mazeOverlayPortrayal.setMap(new SimpleColorMap(#[
			new Color(0,0,0,0), // transparent
			new Color(192, 192, 192, 150)
		]))
		

		// attach the portrayals
		display.detatchAll
		display.attach(mazePortrayal, "Maze")
		display.attach(mazeOverlayPortrayal, "Exploration Progression")
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
		mazeOverlayPortrayal = new FastValueGridPortrayal2D()
		agentsPortrayal = new ContinuousPortrayal2D()
		
		agentsPortrayal.setField(state.agents)
		mazePortrayal.setField(state.maze)
		mazeOverlayPortrayal.setField(state.mazeOverlay)
		
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

