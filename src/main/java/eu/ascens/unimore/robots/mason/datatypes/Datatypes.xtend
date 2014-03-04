package eu.ascens.unimore.robots.mason.datatypes

import ec.util.MersenneTwisterFast
import fj.data.Option
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

@Data class VisibleVictim {
	
	val Double2D dir
	val int nbBotsNeeded
}

@Data class Stats {
	val long step
	val boolean allSecured
	val int nbSecured
	val int nbDiscovered
	val int percentExplored
}

@Data class RandomSync {
	
	val MersenneTwisterFast random
	
	def nextDouble() {
		random.nextDouble
	}
	
	def nextInt(int i) {
		random.nextInt(i)
	}
	
}