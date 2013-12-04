package eu.ascens.unimore.robots.mason.datatypes

import eu.ascens.unimore.robots.geometry.RelativeCoordinates

@Data class Message {
	
}

@Data class RBMessage {
	RBEmitter emitter
	Message message
}

@Data class RBEmitter {
	RelativeCoordinates coord
	String id
}