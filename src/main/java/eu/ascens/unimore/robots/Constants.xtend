package eu.ascens.unimore.robots

class Constants {
	
	public static val SEED = 12345L
	
	
	// use mtpaint to draw it: 0 for walls, 1 for victims, 2 for starting area, rest for nothing
	public static val MAZE = "/maze1.png"
	public static val NB_BOTS = 100
	
	public static val RADIO_RANGE = 60
	public static val RB_RANGE = 30
	public static val VISION_RANGE = 6
	public static val SPEED = 0.15
	
	public static val OBSTACLE_AVOID_TARGET_DISTANCE = 2
	
	public static val NB_WALL_SENSORS = 24
	
	
	public static val STARTING_EXPLORABLE_CRITICALITY = 0.5
	public static val STARTING_VICTIM_CRITICALITY = 1.0
}