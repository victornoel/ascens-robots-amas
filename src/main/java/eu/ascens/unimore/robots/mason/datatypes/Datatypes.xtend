package eu.ascens.unimore.robots.mason.datatypes

import fj.data.Option
import org.eclipse.xtext.xbase.lib.Pair
import sim.util.Double2D

@Data class Message {
	
}

@Data class RBMessage {
	RBEmitter emitter
	Message message
}

@Data class RBEmitter {
	Double2D coord
	String id
	Option<Message> message
}


@Data class SensorReading {
	
	val Double2D dir
	val Pair<Double2D,Double2D> cone
	val boolean hasWall
	val boolean hasBot
}