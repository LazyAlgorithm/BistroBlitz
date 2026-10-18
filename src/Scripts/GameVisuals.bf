using System;
using Tessera;

namespace BistroBlitz;

extension Game
{
	private String mFeedback = new .() ~ delete _;
	private float mFeedbackTime;
	public void ShowFeedback(StringView message) { mFeedback.Set(message); mFeedbackTime = 2.5f; }

	public int32 OrderRecipe(int32 slot)
	{
		switch (slot) { case 0: return order0Recipe; case 1: return order1Recipe; case 2: return order2Recipe; default: return order3Recipe; }
	}
	public int32 OrderOutcome(int32 slot)
	{
		switch (slot) { case 0: return order0Outcome; case 1: return order1Outcome; case 2: return order2Outcome; default: return order3Outcome; }
	}

	public static StringView StationLabel(StationKind kind)
	{
		switch (kind)
		{
		case .Counter: return "ASSEMBLE";
		case .CuttingBoard: return "CHOP";
		case .Stove: return "COOK";
		case .CrateBun: return "BUNS";
		case .CrateMeat: return "RAW PATTIES";
		case .CrateSausage: return "SAUSAGES";
		case .CrateTomato: return "TOMATOES";
		case .CrateCheese: return "CHEESE";
		case .ServingHatch: return "SERVE HERE";
		case .TrashCan: return "DISCARD";
		}
	}

	public Vector3 ScreenPosition(Vector3 world)
	{
		let projection = camera.GetProjection(GUI.AspectRatio) * camera.ViewMatrix;
		let ndc = projection.Project(world);
		return .((ndc.x * 0.5f + 0.5f) * GUI.Width, (0.5f - ndc.y * 0.5f) * GUI.Height, ndc.z);
	}

	public void WorldLabel(Vector3 world, StringView label, Color tint, float width = 100)
	{
		let screen = ScreenPosition(world);
		if (screen.x < 0 || screen.x > GUI.Width || screen.y < 0 || screen.y > GUI.Height) return;
		GUI.Box(screen.x - width * 0.5f, screen.y - 10, width, 23, .(0.045f, 0.10f, 0.14f, 0.94f));
		GUI.Label(screen.x - width * 0.5f + 7, screen.y - 7, label, tint);
	}

	public override void OnGUI()
	{
		if (menu || phase != 1 || camera == null) return;
		for (let station in KitchenStation.All)
		{
			let position = station.Transform.Position + Vector3(0, 1.6f, 0);
			// Station identity is shown in the contextual HUD, leaving the counter unobstructed.
			if (station.isCooking || (station.kind == .CuttingBoard && RecipeBook.CanChop(station.currentItem)))
			{
				let p = ScreenPosition(position);
				GUI.Bar(p.x - 30, p.y + 12, 60, 7, station.progress, RecipeBook.CanCook(station.currentItem) ? Color(0.3f, 0.85f, 0.4f, 1) : Color(1, 0.55f, 0.15f, 1));
			}

		}

	}

	private void UpdateInteractionPrompt()
	{
		if (mFeedbackTime > 0)
		{
			mFeedbackTime -= Time.UnscaledDeltaTime;
			hudNotice.Set(mFeedback);
			return;
		}
		let chef = Player.Local;
		let target = chef?.FindTargetStation();
		if (target == null) { hudNotice.Set("Find ingredients on the left. Cook at the red stoves. Assemble on wood counters. Serve at the teal hatch on the right."); return; }
		let item = target.currentItem;
		StringView action = "E: place / pick up";
		if (target.kind >= .CrateBun && target.kind <= .CrateCheese) action = "E: take ingredient";
		else if (target.kind == .CuttingBoard && RecipeBook.CanChop(item)) action = "HOLD F / SPACE: chop";
		else if (target.kind == .ServingHatch) action = "E: deliver a matching ticket";
		else if (target.kind == .TrashCan) action = "E: discard held food";
		else if (target.kind == .Counter && item != .None && chef.heldItem != .None) action = "E: combine ingredients";
		else if (RecipeBook.CanCook(item) && target.kind == .Stove) action = "Cooking... wait for the patty to brown";
		else if (target.isCooking) action = "READY! E: pick up before it burns";
		hudNotice.Set(scope $"{StationLabel(target.kind)}  |  {(item == .None ? "" : RecipeBook.ItemName(item))}  |  {action}");
	}
}
