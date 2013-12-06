package eu.ascens.unimore.robots

class Constants {
	
	// Simulation
	
	public static val SEED = 12345L
	
	
	// Environment
	
	// use mtpaint to draw it: 0 for walls, 1 for victims, 2 for starting area, rest for nothing
	public static val MAZE = "/maze1.png"
	public static val NB_BOTS = 200
	
	
	// Robots characteristics
	
	public static val RADIO_RANGE = 60
	public static val RB_RANGE = 30
	public static val VISION_RANGE = 6
	public static val SPEED = 0.15
	public static val NB_WALL_SENSORS = 36
	
	
	// Behaviour constants
	
	public static val CRITICALITY_PRECISION = 0.1
	public static val STARTING_EXPLORABLE_CRITICALITY = 0.5
	public static val STARTING_VICTIM_CRITICALITY = 1.0
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE = 3.0
	
	
	// Useful constants based on the others
	
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED = AVOID_VERY_CLOSE_WALL_DISTANCE*AVOID_VERY_CLOSE_WALL_DISTANCE
	public static val VISION_RANGE_SQUARED = Constants.VISION_RANGE*Constants.VISION_RANGE
	public static val RB_RANGE_SQUARED = Constants.RB_RANGE*Constants.RB_RANGE
}