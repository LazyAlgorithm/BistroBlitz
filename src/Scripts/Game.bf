using System;
using System.Collections;
using Tessera;

namespace BistroBlitz;

[Component]
public class Game : Component
{
	public static Game Instance;

	public Camera camera;
	public bool menu = true;

	[Sync] public int32 phase = 0; // 0: Menu/Lobby, 1: Playing, 2: Results
	[Sync] public float matchTimer = 180.0f; // 3 minutes per round
	[Sync] public int32 score = 0;
	[Sync] public int32 ordersDelivered = 0;
	[Sync] public int32 ordersFailed = 0;
	[Sync] public int32 comboCount = 0;

	// Active Order slots (up to 4 concurrent tickets)
	[Sync] public int32 activeOrderCount = 0;
	[Sync] public int32 order0Recipe = -1, order1Recipe = -1, order2Recipe = -1, order3Recipe = -1;
	[Sync] public float order0Time = 0, order1Time = 0, order2Time = 0, order3Time = 0;
	[Sync] public float order0MaxTime = 60, order1MaxTime = 60, order2MaxTime = 60, order3MaxTime = 60;

	// UI Strings for Data Binding
	[Sync] public int32 order0Outcome = 0, order1Outcome = 0, order2Outcome = 0, order3Outcome = 0;

	public String hudScore = new .() ~ delete _;
	public String hudTimer = new .() ~ delete _;
	public String hudOrders = new .() ~ delete _;
	public String hudNotice = new .() ~ delete _;
	public String hudHeldItem = new .() ~ delete _;
	public String hudCombo = new .() ~ delete _;
	public String order0Text = new .() ~ delete _;
	public String order1Text = new .() ~ delete _;
	public String order2Text = new .() ~ delete _;
	public String order3Text = new .() ~ delete _;
	public String resultsTitle = new .() ~ delete _;
	public String resultsScore = new .() ~ delete _;
	public String resultsStars = new .() ~ delete _;
	public String resultsDetail = new .() ~ delete _;
	public String address = new .("127.0.0.1") ~ delete _;
	public String portText = new .("7777") ~ delete _;
	public String notice = new .() ~ delete _;
	public String connectionLabel = new .() ~ delete _;
	public String lobbySummary = new .() ~ delete _;

	public UIDocument mMenu;
	public UIDocument mHud;

	public bool Authority => Scene.Network == null || Scene.Network.IsServer;
	public bool Connected => Scene.Network != null && Scene.Network.Mode != .Offline;
	public uint16 Port => (uint16)Math.Clamp(SceneSerializer.ParseInt(portText), 1024, 65535);

	private int32 mDisplayedPhase = -1;

	private uint32 mRandom = 987654321;
	private float mOrderSpawnCooldown = 0.0f;

	private uint32 NextRandom()
	{
		mRandom = mRandom * 1664525 + 1013904223;
		return mRandom;
	}

	public override void Awake()
	{
		Instance = this;
	}

	public override void OnDestroy()
	{
		if (Instance == this)
			Instance = null;
		Steam.ClearPresence();
		TouchControls.Shown = false;
		TouchControls.Clear();
	}

	public override void Start()
	{
		if (camera == null)
			camera = Scene.FindComponent<Camera>();

		mMenu = GetComponent<UIDocument>();
		InitializeTouchControls();
		InitializeMenus();
		InitializeAudio();
		GameObject.AddComponent<KitchenCustomers>();

		mHud = GameObject.AddComponent<UIDocument>();
		mHud.document.Set("UI/hud.tui");
		mHud.referenceHeight = 1080;
		mHud.referenceWidth = 1920;
		mHud.Enabled = false;

		if (WebPlatform.IsWeb) address.Clear();
		let app = Application.Instance;
		if (app.HasArg("--self-test"))
		{
			RunKitchenTests();
			return;
		}
		let arg = scope String();
		if (app.GetArg("--port", arg))
			portText.Set(arg);

		if (app.HasArg("--host") || app.HasArg("--server"))
		{
			Host(app.HasArg("--direct"));
			if (Connected) StartMatch();
		}
		else if (app.GetArg("--connect", arg))
		{
			address.Set(arg);
			OnJoin();
		}
		else if (app.HasArg("--solo") || app.HasArg("--play"))
		{
			OnQuickPlay();
		}
		else if (WebPlatform.IsWeb && WebRtc.GetCodeFromLink(arg))
		{
			WebPlatform.SetUrlParam("join", "");
			address.Set(arg);
			OnJoin();
		}
	}

	public override void Update()
	{
		UpdateBrowserConnection();
		UpdateMatch(Time.DeltaTime);
		if (mDisplayedPhase != phase)
		{
			mDisplayedPhase = phase;
			if (phase == 1) OnResume();
			else if (phase == 2) ShowResults();
		}
		UpdateUIStrings();
		if (menu) UpdateMenuEntries();
		UpdateAudio();
		MenuAudio();
		UpdateFriendBrowser();
		UpdateTouchControls();

		if (Input.GetKeyDown(.Escape))
		{
			EscapeMenu();
		}
	}

	private void UpdateMatch(float dt)
	{
		if (phase != 1)
			return;

		if (Authority && (Connected || !menu))
		{
			matchTimer = Math.Max(0.0f, matchTimer - dt);

			UpdateOrders(dt);

			if (matchTimer <= 0.0f)
			{
				EndMatch();
			}
		}
	}

	private void UpdateOrders(float dt)
	{
		// Count active orders
		int32 count = 0;
		if (order0Recipe >= 0) count++;
		if (order1Recipe >= 0) count++;
		if (order2Recipe >= 0) count++;
		if (order3Recipe >= 0) count++;
		activeOrderCount = count;

		// Spawn new orders if needed
		mOrderSpawnCooldown -= dt;
		if (count < 4 && mOrderSpawnCooldown <= 0.0f)
		{
			mOrderSpawnCooldown = 18.0f;
			if (order0Recipe < 0) SpawnOrder(0);
			else if (order1Recipe < 0) SpawnOrder(1);
			else if (order2Recipe < 0) SpawnOrder(2);
			else if (order3Recipe < 0) SpawnOrder(3);
		}

		// Decay order timers
		TickOrderSlot(0, ref order0Recipe, ref order0Time, dt);
		TickOrderSlot(1, ref order1Recipe, ref order1Time, dt);
		TickOrderSlot(2, ref order2Recipe, ref order2Time, dt);
		TickOrderSlot(3, ref order3Recipe, ref order3Time, dt);
	}

	private void TickOrderSlot(int32 slot, ref int32 recipeIdx, ref float timer, float dt)
	{
		if (recipeIdx < 0)
			return;

		timer -= dt;
		if (timer <= 0.0f)
		{
			// Order expired / failed!
			recipeIdx = -1;
			ordersFailed++;
			SetOrderOutcome(slot, -1);
			score = Math.Max(0, score - 30);
			comboCount = 0;
			Audio.PlayOneShot2D("Audio/burn.wav", 0.8f, .Effects);
		}
	}

	public void SetOrderOutcome(int32 slot, int32 outcome)
	{
		switch (slot)
		{
		case 0: order0Outcome = outcome;
		case 1: order1Outcome = outcome;
		case 2: order2Outcome = outcome;
		case 3: order3Outcome = outcome;
		}
	}

	private void SpawnOrder(int32 slot)
	{
		SetOrderOutcome(slot, 0);
		mRandom ^= (uint32)Time.Tick;
		int32 recipeIdx = (int32)(NextRandom() % (uint32)RecipeBook.AllRecipes.Count);
		let recipe = RecipeBook.AllRecipes[recipeIdx];

		switch (slot)
		{
		case 0:
			order0Recipe = recipeIdx;
			order0Time = recipe.timeLimit;
			order0MaxTime = recipe.timeLimit;
		case 1:
			order1Recipe = recipeIdx;
			order1Time = recipe.timeLimit;
			order1MaxTime = recipe.timeLimit;
		case 2:
			order2Recipe = recipeIdx;
			order2Time = recipe.timeLimit;
			order2MaxTime = recipe.timeLimit;
		case 3:
			order3Recipe = recipeIdx;
			order3Time = recipe.timeLimit;
			order3MaxTime = recipe.timeLimit;
		}
	}

	public bool SubmitDish(KitchenItem dish, Player player)
	{
		if (!Authority || phase != 1)
			return false;

		// Check active orders
		int32 matchedSlot = -1;
		int32 matchedRecipe = -1;
		float remainingTime = 0.0f;
		float maxTime = 60.0f;

		if (order0Recipe >= 0 && RecipeBook.AllRecipes[order0Recipe].resultItem == dish)
		{
			matchedSlot = 0;
			matchedRecipe = order0Recipe;
			remainingTime = order0Time;
			maxTime = order0MaxTime;
		}
		else if (order1Recipe >= 0 && RecipeBook.AllRecipes[order1Recipe].resultItem == dish)
		{
			matchedSlot = 1;
			matchedRecipe = order1Recipe;
			remainingTime = order1Time;
			maxTime = order1MaxTime;
		}
		else if (order2Recipe >= 0 && RecipeBook.AllRecipes[order2Recipe].resultItem == dish)
		{
			matchedSlot = 2;
			matchedRecipe = order2Recipe;
			remainingTime = order2Time;
			maxTime = order2MaxTime;
		}
		else if (order3Recipe >= 0 && RecipeBook.AllRecipes[order3Recipe].resultItem == dish)
		{
			matchedSlot = 3;
			matchedRecipe = order3Recipe;
			remainingTime = order3Time;
			maxTime = order3MaxTime;
		}

		if (matchedSlot >= 0)
		{
			let recipe = RecipeBook.AllRecipes[matchedRecipe];
			int32 basePoints = recipe.points;
			int32 tipBonus = (remainingTime / maxTime > 0.45f) ? 50 : 0;
			comboCount++;
			int32 comboBonus = Math.Min(comboCount * 15, 100);

			score += (basePoints + tipBonus + comboBonus);
			ordersDelivered++;
			SetOrderOutcome(matchedSlot, 1);

			Audio.PlayOneShot2D("Audio/ding.wav", 0.9f, .Effects);

			// Clear fulfilled order slot
			switch (matchedSlot)
			{
			case 0: order0Recipe = -1;
			case 1: order1Recipe = -1;
			case 2: order2Recipe = -1;
			case 3: order3Recipe = -1;
			}

			// Spawn replacement after a short beat
			mOrderSpawnCooldown = 1.0f;
			return true;
		}

		return false;
	}

	public void StartMatch()
	{
		if (!Authority) return;
		GetComponent<KitchenCustomers>()?.ResetCustomers();
		for (let station in KitchenStation.All) station.ResetStation();
		for (let chef in Player.All)
		{
			chef.heldItem = .None;
			chef.Transform.Position = .((chef.chefId % 4) * 1.2f - 1.8f, 0.2f, -2);
		}
		mOrderSpawnCooldown = 18;
		activeOrderCount = 3;
		phase = 1;
		menu = false;
		matchTimer = 180.0f;
		score = 0;
		ordersDelivered = 0;
		ordersFailed = 0;
		comboCount = 0;

		order0Recipe = -1;
		order1Recipe = -1;
		order2Recipe = -1;
		order3Recipe = -1;

		// Spawn initial orders
		SpawnOrder(0);
		SpawnOrder(1);
		SpawnOrder(2);

		// Ensure local player exists
		if (Player.All.Count == 0 && (Scene.Network == null || Scene.Network.Mode == .Offline))
		{
			let p = Prefab.Create(Scene, "Prefabs/Player.tprefab");
			if (p != null)
			{
				p.Transform.Position = .(0, 0.2f, -2.0f);
			}
		}

		if (mHud != null)
			mHud.Enabled = true;
		if (mMenu != null)
			mMenu.Enabled = false;
	}

	public void EndMatch()
	{
		if (!Authority) return;
		phase = 2;
	}

	private void ShowResults()
	{
		menu = true;

		if (mHud != null)
			mHud.Enabled = false;

		// Star rating calculation
		StringView stars = "⭐";
		if (score >= 1200)
			stars = "⭐⭐⭐ 3 STARS - MICHELIN CHEF!";
		else if (score >= 600)
			stars = "⭐⭐ 2 STARS - GREAT KITCHEN!";
		else
			stars = "⭐ 1 STAR - KEEP COOKING!";

		resultsTitle.Set("SERVICE COMPLETE!");
		resultsScore.Set(scope $"FINAL SCORE: {score}");
		resultsStars.Set(stars);
		resultsDetail.Set(scope $"Dishes Served: {ordersDelivered}   |   Failed: {ordersFailed}");

		if (score >= 600)
			Audio.PlayOneShot2D("Audio/victory.wav", 0.9f, .Effects);
		else
			Audio.PlayOneShot2D("Audio/defeat.wav", 0.9f, .Effects);

		OpenPage(.Results);
	}

	private void UpdateUIStrings()
	{
		int32 minutes = (int32)matchTimer / 60;
		int32 seconds = (int32)matchTimer % 60;
		hudTimer.Set(scope $"{minutes:00}:{seconds:00}");
		hudScore.Set(scope $"SCORE: {score}");

		if (comboCount > 1)
			hudCombo.Set(scope $"COMBO x{comboCount}!");
		else
			hudCombo.Clear();

		if (Player.Local != null && Player.Local.heldItem != .None)
			hudHeldItem.Set(scope $"Holding: {RecipeBook.ItemName(Player.Local.heldItem)}");
		else
			hudHeldItem.Set("Hands Free  |  [E]: Interact / Pick Up  |  [F/Space]: Chop");

		FormatOrderSlot(order0Recipe, order0Time, order0Text);
		FormatOrderSlot(order1Recipe, order1Time, order1Text);
		FormatOrderSlot(order2Recipe, order2Time, order2Text);
		FormatOrderSlot(order3Recipe, order3Time, order3Text);
		for (int32 i < 4)
		{
			let recipe = OrderRecipe(i);
			if (let ticket = mHud?.Find(scope $"order{i}")) ticket.visible = recipe >= 0;
		}
		UpdateInteractionPrompt();

		connectionLabel.Set(Connected ? (Authority ? "HOSTING SESSION" : scope $"CONNECTED TO {address}") : "LOCAL KITCHEN");
		lobbySummary.Set(scope $"Chefs in kitchen: {Player.All.Count}");
		if (WebPlatform.IsWeb && Connected)
		{
			let status = scope String();
			WebRtc.GetStatus(status);
			connectionLabel.Set(scope $"ROOM {WebRtc.RoomCode}  {status}");
		}
	}

	private void FormatOrderSlot(int32 recipeIdx, float timeRemaining, String outText)
	{
		outText.Clear();
		if (recipeIdx >= 0 && recipeIdx < RecipeBook.AllRecipes.Count)
		{
			let r = RecipeBook.AllRecipes[recipeIdx];
			int32 sec = (int32)Math.Max(0.0f, timeRemaining);
			outText.AppendF("{}\n{}\n{:02}s remaining", r.name, r.description, sec);
		}
	}

	public void Host(bool direct = false)
	{
		if (Connected)
			return;

		let net = new NetworkManager(Scene);
		Scene.Network = net;
		net.PlayerPrefab.Set("Player");
		net.Transport = WebPlatform.IsWeb ? .WebRtc : ((!direct && Steam.IsReady) ? .Steam : .Direct);

		if (!net.StartServer(Port, !Application.Instance.Headless))
		{
			notice.Set("Could not host server. Check port or Steam.");
			Scene.Network = null;
			delete net;
			return;
		}

		if (net.Transport == .Steam)
		{
			let room = scope $"{Steam.UserId}";
			Steam.SetPresence("bistro_blitz_room", room);
			Steam.SetPresence("connect", room);
			Steam.SetPresence("status", "Cooking in Bistro Blitz");
		}
		notice.Set(net.Transport == .Steam ? "Steam lobby created! Invite your friends." : "Direct host running.");
	}

	public void OnHost()
	{
		Host();
		if (Connected && Authority) StartMatch();
	}

	public void OnDirectHost()
	{
		Host(true);
		if (Connected && Authority) StartMatch();
	}

	public void OnJoin()
	{
		if (Connected)
		{
			notice.Set("Leave current game first.");
			return;
		}

		if (WebPlatform.IsWeb && !PrepareRoomCode()) return;
		let net = new NetworkManager(Scene);
		Scene.Network = net;
		net.PlayerPrefab.Set("Player");
		net.Transport = WebPlatform.IsWeb ? .WebRtc : ((address.Length >= 16 && !address.Contains('.')) ? .Steam : .Direct);

		if (!net.StartClient(address, Port))
		{
			notice.Set("Could not connect. Check IP and port.");
			Scene.Network = null;
			delete net;
			return;
		}

		mBrowserConnecting = WebPlatform.IsWeb;
		mBrowserWait = 0;
		notice.Set("Connecting to kitchen...");
		menu = false;
		if (mHud != null)
			mHud.Enabled = true;
		if (mMenu != null)
			mMenu.Enabled = false;
	}

	public void OnLeave()
	{
		mBrowserConnecting = false;
		Steam.ClearPresence();
		GetComponent<KitchenCustomers>()?.ResetCustomers();
		let net = Scene.Network;
		if (net != null)
		{
			net.Stop();
			Scene.Network = null;
			for (int i = Player.All.Count - 1; i >= 0; i--)
				Scene.Destroy(Player.All[i].GameObject);
			delete net;
		}

		if (net == null)
			for (int i = Player.All.Count - 1; i >= 0; i--) Scene.Destroy(Player.All[i].GameObject);
		if (mHud != null) mHud.Enabled = false;
		phase = 0;
		menu = true;
		notice.Clear();
		OpenPage(.Main);
	}
}
