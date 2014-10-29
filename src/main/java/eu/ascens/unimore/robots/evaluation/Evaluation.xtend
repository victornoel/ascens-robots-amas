package eu.ascens.unimore.robots.evaluation

import eu.ascens.unimore.robots.mason.InitialisationParameters
import eu.ascens.unimore.robots.mason.datatypes.Stats
import fj.data.List
import org.eclipse.xtend.lib.annotations.Data

interface Parameter {
	
	def String getName()
	def List<ParameterValue> getValues()
}

interface ParameterValue {
	
	def String getName()
	def String getValueName()
	def InitialisationParameters.Builder set(InitialisationParameters.Builder b)
	
}

@Data package class ParameterValueImpl<T> implements ParameterValue {
	
	val String name
	val String valueName
	val T value
	val (InitialisationParameters.Builder, T) => InitialisationParameters.Builder setter
	
	override set(InitialisationParameters.Builder b) {
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
	static def <T> Parameter parameter(String name, (InitialisationParameters.Builder, T) => InitialisationParameters.Builder setter, List<Pair<String,T>> values) {
		new ParameterImpl(
			name,
			values.map[new ParameterValueImpl(name,key,value,setter)]
		)
	}
	
	static def <T> Parameter parameter2(String name, (InitialisationParameters.Builder, T) => InitialisationParameters.Builder setter, List<T> values) {
		new ParameterImpl(
			name,
			values.map[new ParameterValueImpl(name,it.toString,it,setter)]
		)
	}
	
	static def <T> Metric metric(String name, (Stats) => T getter) {
		new MetricImpl(name, getter)
	}
}