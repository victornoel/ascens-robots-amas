package eu.ascens.unimore.robots.mason

import eu.ascens.unimore.robots.beh.datatypes.Explorable
import eu.ascens.unimore.robots.beh.datatypes.ExplorableImpl
import eu.ascens.unimore.robots.beh.datatypes.MySeenVictim
import eu.ascens.unimore.robots.common.SeenVictim
import eu.ascens.unimore.robots.mason.datatypes.Choice
import java.awt.Color
import java.awt.Font
import java.awt.Graphics2D
import java.awt.geom.AffineTransform
import java.awt.geom.Point2D
import sim.portrayal.DrawInfo2D
import sim.portrayal.FieldPortrayal2D
import sim.portrayal.simple.OvalPortrayal2D
import sim.util.Double2D

import static extension fr.irit.smac.lib.contrib.mason.xtend.MasonExtensions.*
import static extension fr.irit.smac.lib.contrib.xtend.JavaExtensions.*

class VictimPortrayal2D extends OvalPortrayal2D {
	
	val FieldPortrayal2D fieldPortrayal
	val AscensSimState state
	
	new(FieldPortrayal2D fieldPortrayal, AscensSimState state) {
		super(Color.RED, 1.4, true)
		this.fieldPortrayal = fieldPortrayal
		this.state = state
	}
	
	override draw(Object object, Graphics2D graphics, DrawInfo2D info) {
		switch object {
			Victim: {
				if (object.secured) {
					this.paint = Color.GREEN
				} else if (object.discovered) {
					this.paint = Color.BLUE
				} else {
					this.paint = Color.RED
				}
			}
		}
		super.draw(object, graphics, info)
	}
}

class BotPortrayal2D extends OvalPortrayal2D {
	
	val FieldPortrayal2D fieldPortrayal
	val ModelProperties properties
	
	new(FieldPortrayal2D fieldPortrayal, ModelProperties properties) {
		super(Color.DARK_GRAY, 1.0, true)
		this.fieldPortrayal = fieldPortrayal
		this.properties = properties
	}
	
	override draw(Object object, Graphics2D graphics, DrawInfo2D info) {
		switch object {
			AscensMasonImpl.RobotImpl.MyMasonRobot: {
				val w = info.draw.width as int
				val h = info.draw.height as int
				val botPos = fieldPortrayal.getObjectLocation(object, info.gui) as Double2D
				val botFPos = fieldPortrayal.getRelativeObjectPosition(botPos, botPos, info)
				
				if (info.selected) {
					this.paint = Color.MAGENTA
				} else {
					this.paint = Color.DARK_GRAY
				}
				
				if (properties.showWallsForAlls || (info.selected && properties.showWalls)) {
					for (wc: object.surroundings.wallCoords.map[new Double2D(it)]) {
						val wp = fieldPortrayal.getRelativeObjectPosition(wc, botPos, info)
						graphics.setPaint(Color.RED)
						graphics.fillRect(wp.x as int, wp.y as int, w, h)
					}
					for (wc: object.surroundings.wallCones) {
						val sloc1 = wc.key + botPos
						val spos1 = fieldPortrayal.getRelativeObjectPosition(sloc1, botPos, info)
						val sloc2 = wc.value + botPos
						val spos2 = fieldPortrayal.getRelativeObjectPosition(sloc2, botPos, info)
						graphics.setPaint(Color.BLUE)
						graphics.drawLine(spos1.x as int, spos1.y as int, spos2.x as int, spos2.y as int)
					}
				}
				
				if (properties.showVisibleForAlls || (info.selected && properties.showVisible)) {
					for (wc: object.surroundings.noWallCoords.map[new Double2D(it)]) {
						val wp = fieldPortrayal.getRelativeObjectPosition(wc, botPos, info)
						graphics.setPaint(Color.GREEN)
						graphics.fillRect(wp.x as int, wp.y as int, w, h)
					}
				}
				
				if (properties.showExplorablesFromOthersForAll || (info.selected && properties.showExplorablesFromOthers)) {
					for(c: object.visu.explorablesFromOthers) {
						graphics.printExplorable(botFPos, botPos, c, info, Color.GREEN)
					}
				}
				
				if (properties.showAreasOnlyFromMeForAll || (info.selected && properties.showAreasOnlyFromMe)) {
					for(c: object.visu.areasOnlyFromMe) {
						graphics.printExplorable(botFPos, botPos, c, info, Color.GREEN)
					}
				}
				
				if (properties.showVictimsFromMeForAll || (info.selected && properties.showVictimsFromMe)) {
					for(c: object.visu.victimsFromMe) {
						val color = switch c {
							MySeenVictim case c.imResponsible: Color.CYAN
							default: Color.GREEN
						}
						graphics.printVisibleVictim(botFPos, botPos, c, info, color)
					}
				}
				
				if (properties.showExplorablesForAll || (info.selected && properties.showExplorables)) {
					for(c: object.visu.explorables) {
						val color = if (c === object.visu.choice) {
							Color.CYAN
						} else {
							Color.GREEN
						}
						graphics.printExplorable(botFPos, botPos, c, info, color)
					}
					val sloc2 = object.visu.move + botPos
					val spos2 = fieldPortrayal.getRelativeObjectPosition(sloc2, botPos, info)
					graphics.setPaint(Color.MAGENTA)
					graphics.fillOval(spos2.x as int, spos2.y as int, w/4, h/4)
				}
				
				if (properties.showChoiceForAll || (info.selected && properties.showChoice)) {
					if (object.visu.choice != null) {
						switch c: object.visu.choice {
							Explorable: {
								graphics.printExplorable(botFPos, botPos, c, info, Color.GREEN)
								if (c instanceof ExplorableImpl) {
									for(ob: c.counting) {
										graphics.printArrow(botFPos, botPos, ob.coord, info, Color.CYAN)
									}
								}
							}
							SeenVictim: {
								graphics.printVisibleVictim(botFPos, botPos, c, info, Color.GREEN)
							}
							Choice: {
								graphics.printArrow(botFPos, botPos, c.direction, info, Color.GREEN)
							}
						}
					}
					val sloc2 = object.visu.move + botPos
					val spos2 = fieldPortrayal.getRelativeObjectPosition(sloc2, botPos, info)
					graphics.setPaint(Color.MAGENTA)
					graphics.fillOval(spos2.x as int, spos2.y as int, w/4, h/4)
				}
				
				if (properties.showSensorReadingsForAll || (info.selected && properties.showSensorReadings)) {
					for(p: object.sensorReadings) {
						val color = if (p.hasWall) {
							Color.PINK
						} else if (p.hasBot) {
							Color.GREEN
						} else {
							Color.MAGENTA
						}
						graphics.printArrow(botFPos, botPos, p.dir, info, color)
					}
				}
				
				if (properties.showVisibleBotsAndVictims && info.selected) {
					val vis = object.surroundings.RBVisibleBotsWithCoordinate.map[coord]
								+ object.surroundings.visibleVictims.map[dir]
					for(b: vis) {
						val sloc = b + botPos
						val spos = fieldPortrayal.getRelativeObjectPosition(sloc, botPos, info)
						graphics.setPaint(Color.BLUE)
						graphics.drawOval((spos.x - (w+2)/2) as int, (spos.y - (h+2)/2) as int, w+2, h+2)
					}
				}
				
				if (properties.showWhoFollowsWhoForAll ||(properties.showWhoFollowsWho && info.selected)) {
					switch c: object.visu.choice {
						ExplorableImpl case c.via.isSome: {
							graphics.printArrow(botFPos, botPos, c.via.some().coord, info, Color.BLUE)
						}
					}
				}
			}
		}
		
		super.draw(object, graphics, info)
	}
	
	def printVisibleVictim(Graphics2D graphics, Point2D.Double botFPos, Double2D botPos, SeenVictim v, DrawInfo2D info, Color color) {
		val toPrint = ""+v.howMuch+"/"+v.nbBotsNeeded
		graphics.printArrow(botFPos, botPos, v.direction, info, color, toPrint)
	}
	
	def printExplorable(Graphics2D graphics, Point2D.Double botFPos, Double2D botPos, Explorable e, DrawInfo2D info, Color color) {
		val toPrint = e.criticality.toShortString(2)
		graphics.printArrow(botFPos, botPos, e.direction, info, color, toPrint)
	}
	
	def printArrow(Graphics2D graphics, Point2D.Double botFPos, Double2D bot, Double2D relativeTarget, DrawInfo2D info, Color color) {
		printArrow(graphics,botFPos,bot,relativeTarget,info,color,null)
	}
	
	def printArrow(Graphics2D graphics, Point2D.Double botFPos, Double2D bot, Double2D relativeTarget, DrawInfo2D info, Color color, String label) {
		
		val target = bot + relativeTarget
		val targetPos = fieldPortrayal.getRelativeObjectPosition(target, bot, info)
		
		graphics.setPaint(color)
		graphics.drawArrow(botFPos.x as int, botFPos.y as int, targetPos.x as int, targetPos.y as int)
		
		if (label != null) {
			graphics.printArrowLabel(label, info, botFPos, targetPos)
		}
	}
	
	val static FONT = new Font("SansSerif",Font.PLAIN, 10)
	def static printArrowLabel(Graphics2D graphics, String s, DrawInfo2D info, Point2D.Double botFPos, Point2D.Double targetPos) {
		
		val lx = botFPos.x*0.2+targetPos.x*0.8
		val ly = botFPos.y*0.2+targetPos.y*0.8
		
		val x = (lx + 0 * info.draw.width + 0) as int
        val y = (ly + 0.5 * info.draw.height + 10) as int
        
        graphics.setPaint(Color.BLACK)
        graphics.setFont(FONT)
        
        graphics.drawString(s,x,y);
	}
	
	val static ARR_SIZE = 5

	def static drawArrow(Graphics2D g1, int x1, int y1, int x2, int y2) {
		val g = g1.create as Graphics2D
		
		val dx = x2 - x1
		val dy = y2 - y1
		val angle = Math.atan2(dy, dx);
		val len = Math.sqrt(dx * dx + dy * dy) as int
		val at = AffineTransform.getTranslateInstance(x1, y1)
		at.concatenate(AffineTransform.getRotateInstance(angle))
		g.transform(at)

		// Draw horizontal arrow starting in (0, 0)
		g.drawLine(0, 0, len, 0)
		g.fillPolygon(#[len, len - ARR_SIZE, len - ARR_SIZE, len],
			#[0, -ARR_SIZE, ARR_SIZE, 0], 4)
	}
	
}