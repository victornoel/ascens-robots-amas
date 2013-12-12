package eu.ascens.unimore.robots.mason

import eu.ascens.unimore.robots.Constants
import eu.ascens.unimore.robots.beh.datatypes.Explorable
import java.awt.Color
import java.awt.Font
import java.awt.Graphics2D
import java.awt.geom.AffineTransform
import java.awt.geom.Point2D
import java.io.IOException
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

abstract class AscensSimState extends SimState {

	package val IntGrid2D maze
	package var Continuous2D agents

	package val double radioRange = Constants.RADIO_RANGE
	package val double visionRange = Constants.VISION_RANGE
	package val double speed = Constants.SPEED
	package val double rbRange = Constants.RB_RANGE
	
	val List<Int2D> availStartingAreas = newArrayList()
	val List<Int2D> usedStartingAreas = newArrayList()
	
	new() throws IOException {
		super(Constants.SEED)

		maze = new IntGrid2D(0, 0)
		val grid = TableLoader.loadPNGFile(this.class.getResourceAsStream(Constants.MAZE))
		maze.setTo(grid)
		
		for(i: 0..<maze.width) {
			for(j: 0..<maze.height) {
				if (maze.get(i,j) == 2) {
					availStartingAreas += new Int2D(i,j)
				}
			}
		}
	}

	abstract def void populate()

	override start() {

		super.start()
		
		availStartingAreas += usedStartingAreas
		usedStartingAreas.clear
		
		agents = new Continuous2D(1, maze.width, maze.height)

		populate()
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
	
	def isVictim(int x, int y) {
		maze.get(x, y) == 1
	}
	
	def add(Steppable r) {
		if (!availStartingAreas.empty) {
			val iPos = availStartingAreas.remove(random.nextInt(availStartingAreas.size))
			usedStartingAreas += iPos
			val pos = new Double2D(iPos.x+0.5, iPos.y+0.5)
			agents.setObjectLocation(r, pos)
			schedule.scheduleRepeating(Schedule.EPOCH, 0, r, 1)
			pos
		} else {
			throw new NoStartingAreaAvailable
		}
		
	}
	
	@Property boolean showSensorReadings = false
	@Property boolean showSensorReadingsForAll = false
	@Property boolean showWalls = false
	@Property boolean showWallsForAlls = false
	@Property boolean showVisible = false
	@Property boolean showVisibleForAlls = false
	@Property boolean showExplorableOnlyFromMe = false
	@Property boolean showExplorableOnlyFromMeForAll = false
	@Property boolean showExplorableFromOthers = false
	@Property boolean showExplorableFromOthersForAll = false
	@Property boolean showExplorable = false
	@Property boolean showExplorableForAll = false
	@Property boolean showVisibleBotsAndVictims = false
	@Property boolean showWhoFollowsWhoForAll = false
	@Property boolean showWhoFollowsWho = false
}

class NoStartingAreaAvailable extends RuntimeException {}

class AscensGUIState extends GUIState {

	val FastValueGridPortrayal2D mazePortrayal = new FastValueGridPortrayal2D();
	val ContinuousPortrayal2D agentPortrayal = new ContinuousPortrayal2D();
	val FastValueGridPortrayal2D homePheromonePortrayal = new FastValueGridPortrayal2D("Home Pheromone");
	val FastValueGridPortrayal2D foodPheromonePortrayal = new FastValueGridPortrayal2D("Food Pheromone");

	// initialised in init
	var Display2D display
	var JFrame displayFrame

	new(AscensSimState state) {
		super(state)
	}
	
	override getSimulationInspectedObject() {
		state
	}

	def setupPortrayals() {
		val state = (state as AscensSimState)

		// TODO
		agentPortrayal.setField(state.agents)
		agentPortrayal.setPortrayalForClass(AscensMasonImpl.RobotImpl.MyMasonRobot, new BotPortrayal2D(agentPortrayal, state))

		// set up the maze portrayal
		//mazePortrayal.setPortrayalForAll(new MazeCellPortrayal(state.maze));
		mazePortrayal.setMap(new SimpleColorMap(0,3,Color.DARK_GRAY,Color.WHITE))
		mazePortrayal.setField(state.maze);

		//robotsPortrayal.setPortrayalForClass(ObstacleObject, new GeomPortrayal(Color.YELLOW,1.0,true))
		//robotsPortrayal.setPortrayalForClass(VictimObject, new GeomPortrayal(Color.RED,1.0,true))
		// reschedule the displayer
		display.reset();

		// redraw the display
		display.repaint();
	}

	override start() {
		super.start()

		setupPortrayals()
	}

	// TODO better
	override init(Controller controller) {
		super.init(controller)

		// Make the Display2D.  We'll have it display stuff later
		val s = state as AscensSimState
		display = new Display2D(s.maze.width * 8, s.maze.height * 8, this)

		// register the frame so it appears in the "Display" list
		displayFrame = display.createFrame();
		controller.registerFrame(displayFrame);
		displayFrame.setVisible(true);

		// attach the portrayals
		display.attach(homePheromonePortrayal, "Pheromones To Home");
		display.attach(foodPheromonePortrayal, "Pheromones To Food");
		display.attach(mazePortrayal, "Maze");
		display.attach(agentPortrayal, "Agents");

		display.setBackdrop(Color.white);
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

class BotPortrayal2D extends OvalPortrayal2D {
	
	val FieldPortrayal2D fieldPortrayal
	val AscensSimState state
	
	new(FieldPortrayal2D fieldPortrayal, AscensSimState state) {
		super(Color.DARK_GRAY, 1.0, true)
		this.fieldPortrayal = fieldPortrayal
		this.state = state
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
				
				if (state.showWallsForAlls || (info.selected && state.showWalls)) {
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
				
				if (state.showVisibleForAlls || (info.selected && state.showVisible)) {
					for (wc: object.surroundings.noWallCoords.map[new Double2D(it)]) {
						val wp = fieldPortrayal.getRelativeObjectPosition(wc, botPos, info)
						graphics.setPaint(Color.GREEN)
						graphics.fillRect(wp.x as int, wp.y as int, w, h)
					}
				}
				
				if (state.showExplorableFromOthersForAll || (info.selected && state.showExplorableFromOthers)) {
					for(c: object.visu.explorablesFromOthers) {
						graphics.printExplorable(c, botPos, botFPos, info)
					}
				}
				
				if (state.showExplorableOnlyFromMeForAll || (info.selected && state.showExplorableOnlyFromMe)) {
					for(c: object.visu.explorablesOnlyFromMe) {
						graphics.printExplorable(c, botPos, botFPos, info)
					}
				}
				
				if (state.showExplorableForAll || (info.selected && state.showExplorable)) {
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
				
				if (state.showSensorReadingsForAll || (info.selected && state.showSensorReadings)) {
					for(p: object.sensorReadings) {
						// get absolute position
						val sloc = p.dir.add(botPos)
						if (!p.hasWall) {
							graphics.setPaint(Color.MAGENTA)
						} else {
							graphics.setPaint(Color.PINK)
						}
						val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
						graphics.fillOval(spos.x as int, spos.y as int, w/2, h/2)
					}
				}
				
				if (state.showVisibleBotsAndVictims && info.selected) {
					val vis = object.surroundings.RBVisibleBotsWithCoordinate.map[value].append(object.surroundings.visibleVictims)
					for(b: vis) {
						val sloc = b.add(botPos)
						val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
						graphics.setPaint(Color.BLUE)
						graphics.drawOval((spos.x - (w+2)/2) as int, (spos.y - (h+2)/2) as int, w+2, h+2)
					}
				}
				
				if (state.showWhoFollowsWhoForAll ||(state.showWhoFollowsWho && info.selected)) {
					if (object.visu.choice != null && object.visu.choice.via != null) {
						val sloc1 = object.visu.choice.via.add(botPos)
						val spos1 = fieldPortrayal.getRelativeObjectPosition(sloc1, botPos, info)
						graphics.setPaint(Color.BLUE)
						graphics.drawArrow(botFPos.x as int, botFPos.y as int, spos1.x as int, spos1.y as int)
					}
				}
			}
		}
		
		super.draw(object, graphics, info)
	}
	
	def printExplorable(Graphics2D graphics, Explorable e, Double2D botPos, Point2D.Double botFPos, DrawInfo2D info) {
		val sloc = e.direction.add(botPos)
		val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
		graphics.setPaint(Color.GREEN)
		graphics.drawArrow(botFPos.x as int, botFPos.y as int, spos.x as int, spos.y as int)
		//graphics.fillOval(spos.x as int, spos.y as int, w/2, h/2)
		printLabel(e.origin+"/"+e.howMuch, graphics, info, spos.x as int, spos.y as int)
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