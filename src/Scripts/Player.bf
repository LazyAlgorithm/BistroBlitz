using System;
using System.Collections;
using Tessera;

namespace BistroBlitz;

[Component]
public class Player : NetworkScript
{
	public static List<Player> All = new .() ~ delete _;
	public static Player Local;

	[Sync] public KitchenItem heldItem = .None;
	[Sync] public int32 chefId = 0;
	[Sync] public bool moving = false;
	[Sync] public bool isChopping = false;
	[Sync] public bool ready = false;
	[Sync] public float locomotionSpeed = 0.0f;

	public bool LocalPlayer =>  Scene.Network == null || Scene.Network.Mode == .Offline || IsOwner;

	private KitchenItem mLastHeldItem = .None;
	private GameObject mChefRoot;
	private GameObject mHeldItemSocket;
	private MeshRenderer mHeldItemRenderer;
	private MeshRenderer mBodyRenderer;
	private float mWalkTimer = 0.0f;
	private float mChopAnimTimer = 0.0f;

	public override void Awake()
	{
		All.Add(this);
		chefId = (int32)All.Count - 1;
		mouseLook = false;
		holdRightMouseToLook = false;
	}

	public override void OnDestroy()
	{
		All.Remove(this);
		if (Local == this)
			Local = null;
		if (mChefRoot != null)
		{
			Scene.Destroy(mChefRoot);
			mChefRoot = null;
		}
	}

	public override void GatherInput(ref NetInput input)
	{
		base.GatherInput(ref input);
	}

	protected override void ReadInput(ref NetInput input)
	{
		if (Game.Instance != null && Game.Instance.menu)
		{
			input.moveX = 0;
			input.moveZ = 0;
			input.buttons = 0;
			return;
		}

		// Pick up or place with E; hold F or Space to chop.
		if (Input.GetKey(.E) || (!TouchControls.Active && Input.GetMouseButton(0)))
		{
			input.SetButton((int32)InputButton.Use, true);
		}

		// Space or F or Right Click can chop
		if (Input.GetKey(.F) || Input.GetKey(.Space) || (!TouchControls.Active && Input.GetMouseButton(1)))
		{
			input.SetButton((int32)InputButton.Ability1, true);
		}
	}

	public override void OnTick(TickInput input, float dt)
	{
		let game = Game.Instance;
		if (game != null && game.phase != 1)
		{
			moving = false;
			return;
		}

		// Top-down 3D movement along X and Z
		Vector3 moveDir = .(input.raw.moveX, 0, input.raw.moveZ);
		if (moveDir.LengthSquared > 1.0f)
			moveDir = moveDir.Normalized;

		let speed = (input.Sprint ? 7.2f : 5.2f);
		GetComponent<CharacterController>()?.SimpleMove(moveDir * speed, dt, 0);

		if (moveDir.LengthSquared > 0.02f)
		{
			let yaw = Math.Atan2(moveDir.x, moveDir.z) * Mathf.Rad2Deg;
			Transform.Rotation = Quaternion.Euler(0, yaw, 0);
		}

		if (Scene.Network == null || Scene.Network.IsServer)
		{
			locomotionSpeed = moveDir.Length * speed;
			moving = moveDir.LengthSquared > 0.02f;

			// Find interactive station in front of chef
			KitchenStation targetStation = FindTargetStation();

			if (input.Pressed(.Use))
			{
				if (targetStation != null)
					targetStation.Interact(this);
			}

			if (input.Held(.Ability1) && targetStation != null && targetStation.kind == .CuttingBoard)
			{
				targetStation.Chop(this, dt);
				isChopping = true;
			}
			else
			{
				isChopping = false;
			}
		}
	}

	public KitchenStation FindTargetStation()
	{
		KitchenStation bestStation = null;
		float bestDist = 2.0f;
		let forwardPoint = Transform.Position + Transform.Forward * 0.9f;

		for (let station in KitchenStation.All)
		{
			var offset = station.Transform.Position - Transform.Position;
			offset.y = 0;
			if (offset.Length > 1.9f || offset.x * Transform.Forward.x + offset.z * Transform.Forward.z < 0.1f) continue;
			let d = (station.Transform.Position - forwardPoint).Length;
			if (d < bestDist)
			{
				bestDist = d;
				bestStation = station;
			}
		}

		return bestStation;
	}

	public override void Update()
	{
		if (LocalPlayer)
		{
			Local = this;


		}

		UpdateChefVisuals();
	}

	private void UpdateChefVisuals()
	{
		if (Application.Instance.Headless)
			return;

		if (mChefRoot == null)
		{
			BuildChefModel();
		}

		// Update held item visual
		if (heldItem != mLastHeldItem)
		{
			mLastHeldItem = heldItem;
			if (heldItem == .None)
			{
				mHeldItemSocket?.SetActive(false);
			}
			else
			{
				mHeldItemSocket?.SetActive(true);
				let meshPath = RecipeBook.ModelFor(heldItem);
				if (!meshPath.IsEmpty)
				{
					mHeldItemRenderer.mesh.Set(meshPath);
					mHeldItemRenderer.texture.Set(RecipeBook.TextureFor(heldItem));
					if (heldItem == .Bun)
					{
						mHeldItemSocket.Transform.LocalScale = .(0.55f, 0.20f, 0.55f);
						mHeldItemRenderer.color = .(0.93f, 0.73f, 0.45f, 1.0f);
					}
					else
					{
						mHeldItemSocket.Transform.LocalScale = .(RecipeBook.DisplayScale(heldItem));
						mHeldItemRenderer.color = RecipeBook.FoodTint(heldItem);
					}
				}
			}
		}

		// Procedural walk and chop animation
		if (moving)
		{
			mWalkTimer += Time.DeltaTime * 14.0f;
			let bob = (float)(Math.Sin(mWalkTimer) * 0.05f);
			let tilt = (float)(Math.Sin(mWalkTimer * 0.5f) * 3.5f);
			mChefRoot.Transform.LocalPosition = .(0, bob, 0);
			mChefRoot.Transform.LocalRotation = Quaternion.Euler(0, 0, tilt);
		}
		else if (isChopping)
		{
			mChopAnimTimer += Time.DeltaTime * 25.0f;
			let chopBob = (float)(Math.Abs(Math.Sin(mChopAnimTimer)) * 0.08f);
			mChefRoot.Transform.LocalPosition = .(0, -chopBob, 0);
			mChefRoot.Transform.LocalRotation = .Identity;
		}
		else
		{
			mChefRoot.Transform.LocalPosition = .Zero;
			mChefRoot.Transform.LocalRotation = .Identity;
		}
	}

	private void BuildChefModel()
	{
		mChefRoot = Scene.CreateGameObject("ChefRoot", Transform);
		mChefRoot.Transient = true;

		// 1. Body / Jacket (Capsule)
		let bodyObj = Scene.CreateGameObject("ChefBody", mChefRoot.Transform);
		bodyObj.Transform.LocalPosition = .(0, 0.65f, 0);
		bodyObj.Transform.LocalScale = .(0.6f, 0.65f, 0.6f);
		mBodyRenderer = bodyObj.AddComponent<MeshRenderer>();
		mBodyRenderer.mesh.Set("builtin:capsule");

		Color[4] apronColors = .(
			.(0.92f, 0.28f, 0.24f, 1.0f), // Red
			.(0.24f, 0.55f, 0.92f, 1.0f), // Blue
			.(0.25f, 0.82f, 0.42f, 1.0f), // Green
			.(0.95f, 0.75f, 0.20f, 1.0f)  // Amber / Yellow
		);
		mBodyRenderer.color = apronColors[Math.Clamp(chefId % 4, 0, 3)];

		// 2. Head (Sphere)
		let headObj = Scene.CreateGameObject("ChefHead", mChefRoot.Transform);
		headObj.Transform.LocalPosition = .(0, 1.25f, 0);
		headObj.Transform.LocalScale = .(0.44f, 0.44f, 0.44f);
		let headRenderer = headObj.AddComponent<MeshRenderer>();
		headRenderer.mesh.Set("builtin:sphere");
		headRenderer.color = .(1.0f, 0.86f, 0.74f, 1.0f);

		// 3. Chef Hat Base (Cylinder)
		let hatBase = Scene.CreateGameObject("ChefHatBase", mChefRoot.Transform);
		hatBase.Transform.LocalPosition = .(0, 1.50f, 0);
		hatBase.Transform.LocalScale = .(0.32f, 0.18f, 0.32f);
		let hatBaseRenderer = hatBase.AddComponent<MeshRenderer>();
		hatBaseRenderer.mesh.Set("builtin:cylinder");
		hatBaseRenderer.color = .White;

		// 4. Chef Hat Puff (Sphere)
		let hatPuff = Scene.CreateGameObject("ChefHatPuff", mChefRoot.Transform);
		hatPuff.Transform.LocalPosition = .(0, 1.70f, 0);
		hatPuff.Transform.LocalScale = .(0.46f, 0.32f, 0.46f);
		let hatPuffRenderer = hatPuff.AddComponent<MeshRenderer>();
		hatPuffRenderer.mesh.Set("builtin:sphere");
		hatPuffRenderer.color = .White;

		// 5. Left & Right Hands
		let handL = Scene.CreateGameObject("HandL", mChefRoot.Transform);
		handL.Transform.LocalPosition = .(-0.35f, 0.72f, 0.3f);
		handL.Transform.LocalScale = .(0.18f, 0.18f, 0.18f);
		let handLRenderer = handL.AddComponent<MeshRenderer>();
		handLRenderer.mesh.Set("builtin:sphere");
		handLRenderer.color = .(1.0f, 0.86f, 0.74f, 1.0f);

		let handR = Scene.CreateGameObject("HandR", mChefRoot.Transform);
		handR.Transform.LocalPosition = .(0.35f, 0.72f, 0.3f);
		handR.Transform.LocalScale = .(0.18f, 0.18f, 0.18f);
		let handRRenderer = handR.AddComponent<MeshRenderer>();
		handRRenderer.mesh.Set("builtin:sphere");
		handRRenderer.color = .(1.0f, 0.86f, 0.74f, 1.0f);

		// 6. Held Item Socket
		mHeldItemSocket = Scene.CreateGameObject("HeldItemSocket", mChefRoot.Transform);
		mHeldItemSocket.Transform.LocalPosition = .(0, 0.78f, 0.62f);
		mHeldItemRenderer = mHeldItemSocket.AddComponent<MeshRenderer>();
		mHeldItemSocket.SetActive(false);
	}
}
