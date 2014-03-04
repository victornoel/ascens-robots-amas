package eu.ascens.unimore.robots.evaluation

import eu.ascens.unimore.robots.mason.InitialisationParametersBuilder
import eu.ascens.unimore.robots.mason.datatypes.Stats
import fj.data.List

interface Parameter {
	
	def String getName()
	def List<ParameterValue> getValues()
}

interface ParameterValue {
	
	def String getName()
	def String getValueName()
	def InitialisationParametersBuilder set(InitialisationParametersBuilder b)
	
}

@Data package class ParameterValueImpl<T> implements ParameterValue {
	
	val String name
	val String valueName
	val T value
	val (InitialisationParametersBuilder, T) => InitialisationParametersBuilder setter
	
	override set(InitialisationParametersBuilder b) {
		setter.apply(b, value)
	}
	
}

@Data package class ParameterImpl<T> implements Parameter {
	
	val String name
	val List<ParameterValue> values
	
}

interface Metric {
	
	def String getName()
	def String get(Stats stat)
}

@Data package class MetricImpl<T> implements Metric {
	
	val String name
	val (Stats) => T getter
	
	override get(Stats stat) {
		getter.apply(stat).toString
	}
}

class Evaluation {
	static def <T> Parameter parameter(String name, (InitialisationParametersBuilder, T) => InitialisationParametersBuilder setter, List<Pair<String,T>> values) {
		new ParameterImpl(
			name,
			values.map[new ParameterValueImpl(name,key,value,setter)]
		)
	}
	
	static def <T> Parameter parameter2(String name, (InitialisationParametersBuilder, T) => InitialisationParametersBuilder setter, List<T> values) {
		new ParameterImpl(
			name,
			values.map[new ParameterValueImpl(name,it.toString,it,setter)]
		)
	}
	
	static def <T> Metric metric(String name, (Stats) => T getter) {
		new MetricImpl(name, getter)
	}
}