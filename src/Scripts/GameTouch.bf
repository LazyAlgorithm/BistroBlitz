using System;
using Tessera;

namespace BistroBlitz;

extension Game
{
	public bool MobileVersion => WebPlatform.IsWeb && WebPlatform.IsMobile;

	private void InitializeTouchControls()
	{
		TouchControls.Clear();
		TouchControls.Shown = false;
		TouchControls.Tint = .(1, 0.92f, 0.76f, 0.95f);
		TouchControls.Backing = .(0.05f, 0.12f, 0.16f, 0.75f);
		TouchControls.EdgeMargin = .(0.04f, 0.025f);
		TouchControls.AddStick("Move", .(0, 0.48f, 0.48f, 0.52f), .(0, 1), .(0.17f, -0.19f), 0.11f);
		TouchControls.AddButton("Use", "USE", .(1, 1), .(-0.16f, -0.20f), 0.085f);
		TouchControls.AddButton("Chop", "CHOP", .(1, 1), .(-0.37f, -0.20f), 0.085f);
		TouchControls.AddButton("Sprint", "RUN", .(0, 1), .(0.17f, -0.43f), 0.06f);
		TouchControls.AddButton("Pause", "MENU", .(1, 0), .(-0.08f, 0.28f), 0.05f);
		if (MobileVersion) UIDocument.SetVariant("mobile", 720, 720);
	}

	private void UpdateTouchControls()
	{
		TouchControls.Shown = MobileVersion && phase == 1 && !menu;
		if (!MobileVersion) return;
		let aspect = Application.Instance.InterfaceWidth / Math.Max(1.0f, Application.Instance.InterfaceHeight);
		if (camera != null) camera.orthographicSize = Math.Max(Math.Clamp(fieldOfView * 0.14f, 7.8f, 11.2f), 9.8f / Math.Max(aspect, 0.25f));
		if (TouchControls.Pressed("Pause")) EscapeMenu();
		if (Player.Local == null || Player.Local.heldItem == .None) hudHeldItem.Set("Drag to move  |  USE: pick up / place / serve  |  Hold CHOP to prepare");
		if (mFeedbackTime <= 0)
		{
			hudNotice.Replace("HOLD F / SPACE:", "HOLD CHOP:");
			hudNotice.Replace("E:", "USE:");
		}
	}
}
