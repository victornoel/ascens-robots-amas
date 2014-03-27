package sim.display;

import java.awt.Point;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.geom.Rectangle2D;

import sim.display.Display2D;
import sim.display.GUIState;
import sim.portrayal.LocationWrapper;
import sim.util.Bag;

public class MultiSelectDisplay2D extends Display2D {

	public MultiSelectDisplay2D(final double width, final double height,
			final GUIState simulation) {
		super(width, height, simulation);

		final MouseListener mouseListener = insideDisplay.getMouseListeners()[0];

		insideDisplay.removeMouseListener(mouseListener);

		// add mouse listener for the inspectors
		insideDisplay.addMouseListener(new MouseAdapter() {
			public void mouseClicked(MouseEvent e) {
				if (handleMouseEvent(e)) {
					repaint();
					return;
				} else {
					// we only care about mouse button 1. Perhaps in the future
					// we may eliminate some key modifiers as well
					int modifiers = e.getModifiers();
					if ((modifiers & e.BUTTON1_MASK) == e.BUTTON1_MASK) {
						final Point point = e.getPoint();
						if (e.getClickCount() == 2)
							createInspectors(new Rectangle2D.Double(point.x,
									point.y, 1, 1), simulation);
						if (e.getClickCount() == 1 || e.getClickCount() == 2) // in
																				// both
																				// situations
						{
							if ((modifiers & e.SHIFT_MASK) != e.SHIFT_MASK) {
								clearSelections();
							}
							performSelection(new Rectangle2D.Double(point.x,
									point.y, 1, 1));
						}
						repaint();
					}
				}
			}

			// clear tool-tip updates
			public void mouseExited(MouseEvent e) {
				mouseListener.mouseExited(e);
			}

			public void mouseEntered(MouseEvent e) {
				mouseListener.mouseEntered(e);
			}

			public void mousePressed(MouseEvent e) {
				mouseListener.mousePressed(e);
			}

			public void mouseReleased(MouseEvent e) {
				mouseListener.mouseReleased(e);
			}
		});
	}

	@Override
	public void performSelection(Bag locationWrappers) {
		if (locationWrappers == null)
			return; // deselect everything

		// add new wrappers
		if (selectionMode == SELECTION_MODE_SINGLE) {
			if (locationWrappers.size() > 0) {
				LocationWrapper wrapper = ((LocationWrapper) (locationWrappers
						.get(locationWrappers.size() - 1))); // get the top one,
																// it's likely
																// the agent
																// drawn last,
																// thus on top.
																// Maybe?
				wrapper.getFieldPortrayal().setSelected(wrapper, true);
				selectedWrappers.add(wrapper);
			}
		} else
			// SELECTION_MODE_MULTI
			for (int x = 0; x < locationWrappers.size(); x++) {
				LocationWrapper wrapper = ((LocationWrapper) (locationWrappers
						.get(x)));
				wrapper.getFieldPortrayal().setSelected(wrapper, true);
				selectedWrappers.add(wrapper);
			}
	}
}
