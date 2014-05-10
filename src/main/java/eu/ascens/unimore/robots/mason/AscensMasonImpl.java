package eu.ascens.unimore.robots.mason;

import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.MDC;

import sim.engine.SimState;
import sim.util.Double2D;
import eu.ascens.unimore.robots.mason.datatypes.Message;
import eu.ascens.unimore.robots.mason.datatypes.RBEmitter;
import eu.ascens.unimore.robots.mason.datatypes.RandomSync;
import eu.ascens.unimore.robots.mason.datatypes.SensorReading;
import eu.ascens.unimore.robots.mason.datatypes.Stats;
import eu.ascens.unimore.robots.mason.datatypes.VisibleVictim;
import eu.ascens.unimore.robots.mason.interfaces.MasonControlAndStats;
import eu.ascens.unimore.robots.mason.interfaces.RobotMovements;
import eu.ascens.unimore.robots.mason.interfaces.RobotPerceptions;
import eu.ascens.unimore.robots.mason.interfaces.RobotVisu;
import fj.data.List;
import fr.irit.smac.may.lib.interfaces.Pull;
import fr.irit.smac.may.lib.interfaces.Push;

public class AscensMasonImpl extends AscensMason {

	private final AscensSimState simState;

	private final AtomicInteger nextId = new AtomicInteger();
	
	@SuppressWarnings("serial")
	public AscensMasonImpl(InitialisationParameters parameters) {
		simState = new AscensSimState(parameters) {
			@Override
			public void newRobot() {
				requires().newRobot().doIt();
			}
		};
	}

	@Override
	protected Pull<InitialisationParameters> make_currentParameters() {
		return new Pull<InitialisationParameters>() {
			@Override
			public InitialisationParameters pull() {
				return simState.getParameters();
			}
		};
	}
	
	@Override
	protected MasonControlAndStats make_control() {
		return new MasonControlAndStats() {
			@Override
			public Stats getCurrentStats() {
				return simState.getCurrentStats();
			}
			
			@Override
			public void startGUI() {
				new AscensGUIState(simState).createController();
			}
			
			@Override
			public void setup() {
				simState.start();
			}
			
			@Override
			public boolean step() {
				return simState.schedule.step(simState);
			}
			
			@Override
			public void shutdown() {
				simState.finish();
			}
		};
	}
	
	@Override
	protected Robot make_Robot() {
		return new RobotImpl();
	}
	
	public class RobotImpl extends Robot {
		
		private Double2D nextMove = null;
		
		private MyMasonRobot bot;
		
		private RandomSync random;
		
		@Override
		protected Pull<RandomSync> make_random() {
			return new Pull<RandomSync>() {
				@Override
				public RandomSync pull() {
					return random;
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
					return bot.sensorReadings();
				}
				
				@Override
				public List<RBEmitter> getRBVisibleRobots() {
					return bot.rbVisibleBotsWithCoordinate();
				}
				
				@Override
				public List<VisibleVictim> getVisibleVictims() {
					return bot.visibleVictims();
				}
				
				@Override
				public boolean isOutOfNest() {
					return bot.isOutOfNest();
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
			
//			public void pushMsg(Message m) {
//				requires().pushRadioMessage().push(m);
//			}
			
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
			this.random = new RandomSync(simState.random);
		}
		
		@Override
		protected Push<Message> make_rbPublish() {
			return new Push<Message>() {
				@Override
				public void push(Message arg0) {
					bot.setMessage(arg0);
				}
			};
		}
		
//		@Override
//		protected Push<Message> make_radioBroadcast() {
//			return new Push<Message>() {
//				@Override
//				public void push(Message arg0) {
//					for(MasonRobot b: bot.radioReachableBots()) {
//						if (b instanceof MyMasonRobot) {
//							((MyMasonRobot)b).pushMsg(arg0);
//						}
//					}
//				}
//			};
//		}
	}
}
