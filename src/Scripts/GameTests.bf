using System;
using Tessera;

namespace BistroBlitz;

extension Game
{
	// Deterministic integration checks against the loaded scene and real station handlers.
	private void RunKitchenTests()
	{
		for (let page in StringView[]("menu", "host", "join", "friends", "settings", "hud", "results"))
		{
			let document = scope UIDocumentData();
			let path = scope String();
			Assets.ResolvePath(scope $"UI/{page}.tui", path);
			Runtime.Assert(document.Load(path) && document.root != null && document.separateStyleFile);
		}
		let modelPath = scope String();
		Assets.ResolvePath("Models/tomato.glb", modelPath);
		let model = Native.tn_gltf_load(modelPath.CStr());
		Runtime.Assert(model != null && Native.tn_gltf_image_count(model) == 1);
		int32 textureWidth = 0, textureHeight = 0;
		let pixels = Native.tn_gltf_get_image(model, 0, &textureWidth, &textureHeight);
		Runtime.Assert(pixels != null && textureWidth == 512 && textureHeight == 512);
		Native.tn_gltf_free(model);
		StartMatch();
		let chef = Player.All[0];
		let customers = GetComponent<KitchenCustomers>();
		customers.StepCustomers(0);
		Runtime.Assert(customers.GuestCount == 3);
		Runtime.Assert(camera.orthographic);
		GUI.Width = 1920;
		GUI.Height = 1080;
		for (let station in KitchenStation.All)
		{
			let screen = ScreenPosition(station.Transform.Position + Vector3(0, 1.6f, 0));
			Runtime.Assert(screen.x > 100 && screen.x < 1820 && screen.y > 175 && screen.y < 920);
		}
		KitchenStation stove = null, board = null, counter = null, buns = null, hatch = null;
		for (let station in KitchenStation.All)
		{
			switch (station.kind)
			{
			case .Stove: stove = station;
			case .CuttingBoard: board = station;
			case .Counter: counter = station;
			case .CrateBun: buns = station;
			case .ServingHatch: hatch = station;
			default:
			}
		}
		Runtime.Assert(stove != null && board != null && counter != null && buns != null && hatch != null);
		buns.Interact(chef);
		Runtime.Assert(chef.heldItem == .Bun);
		counter.Interact(chef);
		Runtime.Assert(counter.currentItem == .Bun && chef.heldItem == .None);
		chef.heldItem = .RawMeat;
		stove.Interact(chef);
		stove.AdvanceCookingForTest(4.6f);
		Runtime.Assert(stove.currentItem == .CookedMeat);
		stove.Interact(chef);
		counter.Interact(chef);
		Runtime.Assert(counter.currentItem == .Burger && chef.heldItem == .None);
		counter.Interact(chef);
		order0Recipe = 0;
		order0Time = 60;
		hatch.Interact(chef);
		customers.StepCustomers(0);
		Runtime.Assert(customers.LeavingHappy(0));
		customers.StepCustomers(100);
		customers.StepCustomers(0);
		Runtime.Assert(customers.GuestCount == 2);
		Runtime.Assert(ordersDelivered == 1 && score == 215 && chef.heldItem == .None);
		chef.heldItem = .Tomato;
		board.Interact(chef);
		board.Chop(chef, 2.1f);
		Runtime.Assert(board.currentItem == .SlicedTomato);
		chef.heldItem = .RawSausage;
		stove.Interact(chef);
		stove.AdvanceCookingForTest(4.6f);
		stove.AdvanceCookingForTest(6.1f);
		Runtime.Assert(stove.currentItem == .BurntMeat && stove.isBurnt);
		order0Recipe = 0;
		order0Time = 0.01f;
		UpdateOrders(0.1f);
		Runtime.Assert(ordersFailed == 1 && comboCount == 0 && score == 185);
		matchTimer = 0.01f;
		UpdateMatch(0.1f);
		Runtime.Assert(phase == 2);
		Runtime.Assert(OrderOutcome(0) == -1);
		StartMatch();
		Runtime.Assert(Player.All.Count == 1);
		Runtime.Assert(phase == 1 && score == 0 && stove.currentItem == .None && board.currentItem == .None);
		Console.WriteLine("BistroBlitz integration checks passed: crates, cooking, assembly, serving, chopping, burning, expiry, results, restart, customer arrivals/departures, UI documents, camera framing, decoded food palette.");
		Application.Instance.Running = false;
	}
}

extension KitchenStation
{
	public void AdvanceCookingForTest(float dt) { UpdateCooking(dt); }
}
