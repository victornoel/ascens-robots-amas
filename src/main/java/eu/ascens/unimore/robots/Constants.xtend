package eu.ascens.unimore.robots

import eu.ascens.unimore.robots.beh.BehaviourImpl
import eu.ascens.unimore.robots.disperse.DisperseBehaviour
import eu.ascens.unimore.robots.disperse.DisperseBehaviourWithTweaks
import eu.ascens.unimore.robots.levy.LevyBehaviourImpl

class SimulationConstants {
	
	public static val String[] MAZES = #[ "maze1", "maze2", "maze3", "maze4", "maze5" ]
	
	public static val BEHAVIOURS = <() => Behaviour>newArrayList(
		[|new BehaviourImpl(true)],
		[|new BehaviourImpl(false)],
		[|new DisperseBehaviourWithTweaks],
		[|new DisperseBehaviour],
		[|new LevyBehaviourImpl]
	)
	
	public static val SEED = 12345L
	
	// environment
	/**
	 *  use mtpaint to draw it:
	 * color index 0 for walls
	 * 1 for victims
	 * 2 for starting area
	 * 3 for an explorable area (do not set to 3 an inaccessible area)
	 * rest for nothing
	*/
	public static val DEFAULT_MAZE = MAZES.get(1)
	public static val NB_BOTS = 200
	public static val MIN_BOTS_PER_VICTIM = 3
	public static val MAX_BOTS_PER_VICTIM = 3
	public static val NB_VICTIMS = 100
	
	// Robots characteristics, in meters or meters/step
	//public static val RADIO_RANGE = 60.0
	public static val RB_RANGE = 20.0
	public static val WALL_RANGE = 3.0
	public static val PROXIMITY_RANGE = WALL_RANGE/2.0
	public static val VICTIM_RANGE = WALL_RANGE
	public static val SPEED = 0.15
	public static val NB_WALL_SENSORS = 24
	
	// bots behaviour
	public static val DEFAULT_BEHAVIOUR = BEHAVIOURS.get(0)
	
	public static val WALL_RANGE_SQUARED = WALL_RANGE*WALL_RANGE
}

class UIConstants {
	
	public static val String[] MAZES = SimulationConstants.MAZES
	
	public static val String[] BEHAVIOURS = #[
		"AMAS (Exploration+Victims)",
		"AMAS (Exploration)",
		"Disperse (With Tweaks)",
		"Disperse (Without Tweaks)",
		"Levy"
	]
	
}

class RequirementsConstants {
	
	// used by evaluation but also by behaviours
	public static val CONSIDERED_NEXT_TO_VICTIM_DISTANCE = 0.5
	
	// useful
	public static val CONSIDERED_NEXT_TO_VICTIM_DISTANCE_SQUARED = CONSIDERED_NEXT_TO_VICTIM_DISTANCE*CONSIDERED_NEXT_TO_VICTIM_DISTANCE
}