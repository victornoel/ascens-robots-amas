package eu.ascens.unimore.robots

class Constants {
	
	// Simulation
	
	public static val SEED = 12345L
	
	// Environment
	
	// use mtpaint to draw it: color index 0 for walls, 1 for victims, 2 for starting area, rest for nothing
	public static val String[] MAZES = #[ "maze1", "maze2", "maze3", "maze4", "maze5" ]
	public static val DEFAULT_MAZE = "maze1"
	public static val NB_BOTS = 60
	
	// Robots characteristics, in meters or meters/step
	public static val RADIO_RANGE = 60
	public static val RB_RANGE = 20
	public static val WALL_RANGE = 3
	public static val PROXIMITY_RANGE = 2
	public static val SPEED = 0.15
	public static val NB_WALL_SENSORS = 24
	
	// TODO to be deleted!!!
	public static val WALL_RANGE_SQUARED = WALL_RANGE*WALL_RANGE
	
}