package eu.ascens.unimore.robots.beh

class CoopConstants {
	
	// Behaviour constants
	
	// for these info, other agents do not rely on the fact
	// an agent use them
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE = 1.0
		
	public static val CRITICALITY_PRECISION = 0.01
	public static val STARTING_EXPLORABLE_CRITICALITY = 0.5
	public static val MAX_CRITICALITY = 1.0
	
	// Useful constants based on the others
	
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED = AVOID_VERY_CLOSE_WALL_DISTANCE*AVOID_VERY_CLOSE_WALL_DISTANCE
	
	// crit starts at 0
	public static val VICTIM_RANGE_CRITICALITY = MAX_CRITICALITY - STARTING_EXPLORABLE_CRITICALITY
}