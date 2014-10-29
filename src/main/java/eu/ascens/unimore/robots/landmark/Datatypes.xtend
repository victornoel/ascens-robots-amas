package eu.ascens.unimore.robots.landmark

import eu.ascens.unimore.robots.mason.datatypes.Message
import org.eclipse.xtend.lib.annotations.Data

@Data class LandmarkData {
	val boolean victim_nearby = false
	val boolean victim_landmark_nearby = false
	val double dist_to_closest_landmark = Double.POSITIVE_INFINITY
	val int mark = 0
}

@Data class RBData extends Message {
	
	val State state
	
}

@Data class RBDataLandmark extends RBData {
	
	val int mark
	
	new(State state, int mark) {
		super(state)
		switch state {
			case TEMPORARY:{}
			case FIRST:{}
			case STABLE:{}
			case VICTIM:{}
			default: new RuntimeException("must be a landmark")
		}
		this.mark = mark
	}
	
}

@Data class RBDataExiting extends RBData {
	
	val double distance
	
	new(double distance) {
		super(State.EXIT)
		this.distance = distance
	}
	
}

enum State {
	WANDER,
	EXIT,
	EXPLORE,
	TEMPORARY,
	FIRST,
	STABLE,
	VICTIM
	
}