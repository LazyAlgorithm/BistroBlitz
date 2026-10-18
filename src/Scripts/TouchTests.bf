using System;
using Tessera;

namespace BistroBlitz;

extension Game
{
	private void RunTouchTests()
	{
		// A desktop build must never expose the mobile overlay.
		UpdateTouchControls();
		Runtime.Assert(!TouchControls.Shown);
		Runtime.Assert(InputActions.Find("Move") != null && InputActions.Find("Use") != null && InputActions.Find("Ability1") != null);
		let app = Application.Instance;
		let oldWidth = app.InterfaceWidth;
		let oldHeight = app.InterfaceHeight;
		for (let screen in Vector2[3](.(1280, 720), .(720, 1280), .(1024, 768)))
		{
			app.InterfaceWidth = screen.x;
			app.InterfaceHeight = screen.y;
			TouchControls.Shown = true;
			let use = TouchControls.Find("Use");
			let chop = TouchControls.Find("Chop");
			let move = TouchControls.Find("Move");
			let useFinger = scope Finger();
			let chopFinger = scope Finger();
			let moveFinger = scope Finger();
			useFinger.position = use.Center(screen);
			chopFinger.position = chop.Center(screen);
			moveFinger.position = move.Center(screen);
			TouchControls.FingerDown(useFinger);
			TouchControls.FingerDown(chopFinger);
			TouchControls.FingerDown(moveFinger);
			Runtime.Assert(useFinger.owner == use && chopFinger.owner == chop && moveFinger.owner == move);
			moveFinger.position.x += move.RadiusPixels(screen) * 0.8f;
			TouchControls.Update();
			Runtime.Assert(use.Held && chop.Held && move.vector.x > 0.7f);
			useFinger.down = false;
			TouchControls.Update();
			Runtime.Assert(!use.Held && chop.Held);
			for (let control in TouchControls.Controls)
			{
				control.finger = null;
				control.value = control.previous = 0;
				control.vector = .Zero;
			}
			useFinger.owner = chopFinger.owner = moveFinger.owner = null;
		}
		app.InterfaceWidth = oldWidth;
		app.InterfaceHeight = oldHeight;
		TouchControls.Shown = false;
	}
}
