package eu.ascens.unimore.robots.mason;

import java.util.concurrent.atomic.AtomicInteger;

import org.eclipse.xtext.xbase.lib.Pair;
import org.slf4j.MDC;

import sim.engine.SimState;
import sim.util.Double2D;
import ec.util.MersenneTwisterFast;
import eu.ascens.unimore.robots.mason.datatypes.Message;
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter;
import eu.ascens.unimore.robots.mason.datatypes.SensorReading;
import eu.ascens.unimore.robots.mason.interfaces.RobotMovements;
import eu.ascens.unimore.robots.mason.interfaces.RobotPerceptions;
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu;
import fj.F;
import fj.data.List;
import fj.data.Option;
import fr.irit.smac.may.lib.interfaces.Pull;
import fr.irit.smac.may.lib.interfaces.Push;

public class AscensMasonImpl extends AscensMason {

	private final AscensSimState simState;

	private final AtomicInteger nextId = new AtomicInteger();
	
	@SuppressWarnings("serial")
	public AscensMasonImpl() {
		simState = new AscensSimState() {
			@Override
			public void populate() {
				requires().populateWorld().doIt();
			}
		};
	}
	
	@Override
	protected void start() {
		super.start();
		new AscensGUIState(simState).createController();
	}
	
	
	@Override
	protected Robot make_Robot() {
		return new RobotImpl();
	}
	
	public class RobotImpl extends Robot {
		
		private Double2D nextMove = null;
		
		private MyMasonRobot bot;
		
		@Override
		protected Pull<MersenneTwisterFast> make_random() {
			return new Pull<MersenneTwisterFast>() {
				@Override
				public MersenneTwisterFast pull() {
					return simState.random;
				}
			};
		}
		
		@Override
		protected RobotMovements make_move() {
			return new RobotMovements() {
				@Override
				public void setNextMove(Double2D m) {
					nextMove = m;
				}
			};
		}
		
		@Override
		protected RobotPerceptions make_see() {
			return new RobotPerceptions() {
				
				@Override
				public List<SensorReading> getSensorReadings() {
					return bot.getSensorReadings();
				}
				
				@Override
				public List<RBEmitter> getRBVisibleRobots() {
					return bot.getRBVisibleBotsWithCoordinate().map(new F<Pair<MasonRobot,Double2D>, RBEmitter>() {
						@Override
						public RBEmitter f(Pair<MasonRobot, Double2D> p) {
							return new RBEmitter(p.getValue(), p.getKey().id, ((MyMasonRobot)p.getKey()).lastMsgs());
						}
					});
				}
				
				@Override
				public List<Double2D> getVisibleVictims() {
					return bot.getVisibleVictims();
				}
			};
		}
		
		@Override
		protected Pull<String> make_id() {
			return new Pull<String>() {
				@Override
				public String pull() {
					return bot.id;
				}
			};
		}
		
		class MyMasonRobot extends MasonRobot {
			
			private static final long serialVersionUID = 7654107358044750292L;

			public MyMasonRobot() {
				super(simState, ""+nextId.getAndIncrement());
			}
			
			@Override
			public void step(SimState state) {
				MDC.put("time", "" + state.schedule.getTime());
				MDC.put("agentName", "" + id);
				super.step(state);
				RobotImpl.this.requires().step().doIt();
				if (nextMove != null) {
					applyMove(nextMove);
					nextMove = null;
				}
			}
			
			public void pushMsg(Message m) {
				requires().pushRadioMessage().push(m);
			}
			
			public Option<Message> lastMsgs() {
				return Option.fromNull(lastMsgs);
			}
			
			public String id() {
				return id;
			}
			
			public RobotVisu visu() {
				return requires().visu();
			}
			
			@Override
			public String toString() {
				return id+super.toString();
			}
		}
		
		@Override
		protected void start() {
			super.start();
			this.bot = new MyMasonRobot();
		}
		
		private Message lastMsgs = null;

		@Override
		protected Push<Message> make_rbPublish() {
			return new Push<Message>() {
				@Override
				public void push(Message arg0) {
					lastMsgs = arg0;
				}
			};
		}
		
		@Override
		protected Push<Message> make_radioBroadcast() {
			return new Push<Message>() {
				@Override
				public void push(Message arg0) {
					for(MasonRobot b: bot.getRadioReachableBots()) {
						if (b instanceof MyMasonRobot) {
							((MyMasonRobot)b).pushMsg(arg0);
						}
					}
				}
			};
		}
	}
	
}
