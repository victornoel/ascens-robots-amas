package eu.ascens.unimore.robots.mason

import de.oehme.xtend.contrib.Buildable
import de.oehme.xtend.contrib.Cached
import eu.ascens.unimore.robots.Behaviour
import eu.ascens.unimore.robots.SimulationConstants
import eu.ascens.unimore.robots.UIConstants
import eu.ascens.unimore.robots.common.Radiangle
import eu.ascens.unimore.robots.mason.datatypes.Stats
import java.awt.Color
import java.util.List
import javax.swing.JFrame
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import sim.display.Controller
import sim.display.Display2D
import sim.display.GUIState
import sim.display.MultiSelectDisplay2D
import sim.engine.Schedule
import sim.engine.SimState
import sim.engine.Steppable
import sim.field.continuous.Continuous2D
import sim.field.grid.IntGrid2D
import sim.portrayal.SimpleInspector
import sim.portrayal.continuous.ContinuousPortrayal2D
import sim.portrayal.grid.FastValueGridPortrayal2D
import sim.portrayal.inspector.TabbedInspector
import sim.util.Double2D
import sim.util.Int2D
import sim.util.TableLoader
import sim.util.gui.SimpleColorMap

import static eu.ascens.unimore.robots.common.GeometryExtensions.*
import static fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*

@Data
@Buildable
class InitialisationParameters {
	
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
		Radiangle.buildCones(nbProximityWallSensors)
			.map[
				val cone = it.key.toNormalizedVector -> it.value.toNormalizedVector
				middleAngledVector(cone.key, cone.value) -> cone
			].sort(ORD_D2D.comap[key]) // sort evaluates
	}
	
	@Cached
	def int visionDistance() {
		Math.ceil(
			Math.max(
				Math.max(rbRange, wallRange),
				Math.max(victimRange, proximityBotRange)
			)
		) as int
	}
}

class Maze extends IntGrid2D {
	
	@Accessors val int nbAreasToExplore
	@Accessors val List<Int2D> availStartingAreas = newArrayList
	@Accessors val List<Int2D> availVictimAreas = newArrayList
	
	new(String filename) {
		super(0,0)
		setTo(TableLoader.loadPNGFile(this.class.getResourceAsStream(filename)))
		
		var nbAtE = 0
		for(i: 0..<width) {
			for(j: 0..<height) {
				val type = get(i,j)
				val iPos = new Int2D(i,j)
				if (type == 2) {
					availStartingAreas += iPos
				}
				if (type == 1) {
					availVictimAreas += iPos
				}
				if (type == 1 || type == 2 || type == 3) {
					nbAtE = nbAtE + 1
				}
			}
		}
		
		nbAreasToExplore = nbAtE
	}
	
}

abstract class AscensSimState extends SimState {

	var Maze maze
	def getMaze() { maze }
	var IntGrid2D mazeOverlay
	def getMazeOverlay() { mazeOverlay }
	var Continuous2D agents
	def getAgents() { agents }
	
	@Accessors var InitialisationParameters parameters
		
	val List<Victim> victims = newArrayList
	val List<Steppable> bots = newArrayList

	new(InitialisationParameters parameters) {
		super(parameters.seed)
		this.parameters = parameters
	}

	abstract def void newRobot()

	override start() {
		super.start()
		
		maze = new Maze("/"+this.parameters.map+".png")
		
		mazeOverlay = new IntGrid2D(maze.width, maze.height)
		mazeOverlay.setTo(0)
		
		agents = new Continuous2D(1, maze.width, maze.height)
		
		try {
			for (i : 1..this.parameters.nbVictims) {
				victims += new Victim(this)
			}
		} catch (NoVictimAreaAvailable e) {
			println("no more victim area available, created " + victims.size + " victims.")
		}
		
		var nbCreated = 0
		try {
			for(i: 1..this.parameters.nbBots) {
				newRobot()
				nbCreated = i
			}
		} catch (NoStartingAreaAvailable e) {
			println("no more starting area available, created "+nbCreated+" robots.")
		}
		
		for(b: bots) {
			schedule.scheduleRepeating(Schedule.EPOCH, 0, b, 1)
		}
	}
	
	override finish() {
		maze = null
		mazeOverlay = null
		agents = null
		victims.clear
		bots.clear
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
	
	def isExplored(int x, int y) {
		mazeOverlay.get(x,y) == 1
	}
	
	def setExplored(int x, int y) {
		mazeOverlay.set(x,y, 1)
	}
	
	def add(MasonRobot r) {
		val pos = addOrThrow(r, maze.availStartingAreas, new NoStartingAreaAvailable)
		bots += r
		pos
	}
	
	def add(Victim v) {
		addOrThrow(v, maze.availVictimAreas, new NoVictimAreaAvailable)
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
				if (isExplored(i,j)) {
					nbExplored = nbExplored + 1
				}
			}
		}
		
		new Stats(
			schedule.steps,
			allSecured,
			nbSecured,
			nbDiscovered,
			(((nbExplored as double)/(maze.nbAreasToExplore as double))*100) as int
		)
	}
}

class NoStartingAreaAvailable extends RuntimeException {}
class NoVictimAreaAvailable extends RuntimeException {}

class VisualisationProperties {
	@Accessors boolean showSensorReadings = false
	@Accessors boolean showSensorReadingsForAll = false
	@Accessors boolean showWalls = false
	@Accessors boolean showWallsForAlls = false
	@Accessors boolean showVisible = false
	@Accessors boolean showVisibleForAlls = false
	@Accessors boolean showAreasOnlyFromMe = false
	@Accessors boolean showAreasOnlyFromMeForAll = false
	@Accessors boolean showVictimsFromMe = false
	@Accessors boolean showVictimsFromMeForAll = false
	@Accessors boolean showExplorablesFromOthers = false
	@Accessors boolean showExplorablesFromOthersForAll = false
	@Accessors boolean showExplorables = false
	@Accessors boolean showExplorablesForAll = false
	@Accessors boolean showChoice = false
	@Accessors boolean showChoiceForAll = false
	@Accessors boolean showVisibleBotsAndVictims = false
	@Accessors boolean showWhoFollowsWhoForAll = false
	@Accessors boolean showWhoFollowsWho = false
}

class ModelProperties {
	
	var InitialisationParameters currentParameters
	
	def buildParameters() {
		val b = InitialisationParameters.builder() => [
			map(SimulationConstants.MAZES.get(map))
			newBehaviour(SimulationConstants.BEHAVIOURS.get(behaviour))
			wallRange(wallRange)
			victimRange(victimRange)
			proximityBotRange(proximityBotRange)
			speed(speed)
			rbRange(rbRange)
			nbProximityWallSensors(nbProximityWallSensors)
			nbBots(nbBots)
			nbVictims(nbVictims)
			minBotsPerVictim(minBotsPerVictim)
			maxBotsPerVictim(maxBotsPerVictim)
		]
		b.build
	}
	
	new(InitialisationParameters parameters) {
		this.currentParameters = parameters
		wallRange = parameters.wallRange
		victimRange = parameters.victimRange
		proximityBotRange = parameters.proximityBotRange
		speed = parameters.speed
		rbRange = parameters.rbRange
		nbProximityWallSensors = parameters.nbProximityWallSensors
		nbBots = parameters.nbBots
		nbVictims = parameters.nbVictims
		minBotsPerVictim = parameters.minBotsPerVictim
		maxBotsPerVictim = parameters.maxBotsPerVictim
		behaviour = SimulationConstants.BEHAVIOURS.indexOf(parameters.newBehaviour)
		map = SimulationConstants.MAZES.indexOf(parameters.map)
	}
	
	@Accessors double wallRange
	@Accessors double victimRange
	@Accessors double proximityBotRange
	@Accessors double speed
	@Accessors double rbRange
	@Accessors int nbProximityWallSensors
	@Accessors int nbBots
	@Accessors int nbVictims
	@Accessors int minBotsPerVictim
	@Accessors int maxBotsPerVictim
	
	@Accessors int behaviour
	def Object domBehaviour() {
		UIConstants.BEHAVIOURS
	}
	
	@Accessors int map
	def Object domMap() {
		UIConstants.MAZES
	}
}

class AscensGUIState extends GUIState {

	// initialised in start
	var FastValueGridPortrayal2D mazePortrayal
	var FastValueGridPortrayal2D mazeOverlayPortrayal
	var ContinuousPortrayal2D agentsPortrayal
	
	// initialised in init
	var Display2D display
	var JFrame displayFrame

	val ModelProperties modelProperties
	val VisualisationProperties visualisationProperties
	
	new(AscensSimState state) {
		super(state)
		modelProperties = new ModelProperties(state.parameters)
		visualisationProperties = new VisualisationProperties
	}
	
	override getInspector() {
		val i = new TabbedInspector(false)
		i.addInspector(new SimpleInspector(visualisationProperties, this, null, getMaximumPropertiesForInspector()), "Visualisation")
		i.addInspector(new SimpleInspector(modelProperties, this, null, getMaximumPropertiesForInspector()), "Model")
		i
	}

	def setupPortrayals() {
		val state = state as AscensSimState
		
		agentsPortrayal.setPortrayalForClass(AscensMasonImpl.RobotImpl.MyMasonRobot, new BotPortrayal2D(agentsPortrayal, visualisationProperties))
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
		val state = (state as AscensSimState)
		
		state.parameters = modelProperties.buildParameters
		
		super.start()
		
		mazePortrayal = new FastValueGridPortrayal2D()
		mazeOverlayPortrayal = new FastValueGridPortrayal2D()
		agentsPortrayal = new ContinuousPortrayal2D()
		
		agentsPortrayal.setField(state.agents)
		mazePortrayal.setField(state.maze)
		mazeOverlayPortrayal.setField(state.mazeOverlay)
		
		setupPortrayals()
	}

	override init(Controller controller) {
		super.init(controller)

		// Make the Display2D.  We'll have it display stuff later
		display = new MultiSelectDisplay2D(800, 800, this)

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

