package eu.ascens.unimore.robots.beh

class CoopConstants {
	
	// this one takes over all the other
	public static val COOPERATION = true
	// this one is related to choosing a direction with respect to other bots position and last choice	
	public static val COOPERATION1 = true
	
	// Behaviour constants
	
	// for these info, other agents do not rely on the fact
	// an agent use them
	public static val CRITICALITY_PRECISION = 0.01
	public static val STARTING_EXPLORABLE_CRITICALITY = 0.5
	public static val MAX_CRITICALITY = 1.0
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE = 1.0
	/**
	 * 0.0 so that we stop ON the victim: important so that
	 * other can properly evaluate if I'm taking care of it or
	 * of another one 
	*/  
	public static val STOP_NEXT_TO_VICTIM_DISTANCE = 0.0
	public static val HOW_MUCH_PER_VICTIM = 4
	
	// for this one, several agents relies on the fact
	// they use the same!
	public static val CONSIDERED_NEXT_TO_VICTIM_DISTANCE = 1.0
	
	// Useful constants based on the others
	
	public static val AVOID_VERY_CLOSE_WALL_DISTANCE_SQUARED = AVOID_VERY_CLOSE_WALL_DISTANCE*AVOID_VERY_CLOSE_WALL_DISTANCE
	public static val CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED = CONSIDERED_NEXT_TO_VICTIM_DISTANCE*CONSIDERED_NEXT_TO_VICTIM_DISTANCE
	
	// crit starts at 0
	public static val VICTIM_SLICE_CRITICALITY = (MAX_CRITICALITY - STARTING_EXPLORABLE_CRITICALITY) / HOW_MUCH_PER_VICTIM
	public static val EXPLORABLE_SLICE_CRITICALITY = STARTING_EXPLORABLE_CRITICALITY / 10
}