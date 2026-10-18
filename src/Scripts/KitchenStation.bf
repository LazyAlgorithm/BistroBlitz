using System;
using System.Collections;
using Tessera;

namespace BistroBlitz;

[Component]
public class KitchenStation : Component
{
	public static List<KitchenStation> All = new .() ~ delete _;

	[Sync] public StationKind kind = .Counter;
	[Sync] public KitchenItem currentItem = .None;
	[Sync] public float progress = 0.0f;
	[Sync] public bool isCooking = false;
	[Sync] public bool isBurnt = false;

	private MeshRenderer mSelection;

	private KitchenItem mLastItem = .None;
	private GameObject mItemDisplay;
	private MeshRenderer mItemRenderer;
	private float mSizzleTimer = 0.0f;
	private float mChopAudioTimer = 0.0f;

	public override void Awake()
	{
		All.Add(this);
	}

	public override void OnDestroy()
	{
		All.Remove(this);
		if (mItemDisplay != null)
		{
			Scene.Destroy(mItemDisplay);
			mItemDisplay = null;
		}
	}

	public void ResetStation()
	{
		currentItem = .None;
		progress = 0;
		isCooking = false;
		isBurnt = false;
	}

	public override void Update()
	{
		if (Game.Instance != null && Game.Instance.Authority && Game.Instance.phase == 1 && (Game.Instance.Connected || !Game.Instance.menu))
			UpdateCooking(Time.DeltaTime);
		UpdateVisuals();
		UpdateStoveEffects();
	}

	private void UpdateCooking(float dt)
	{
		// Stove cooking logic (runs on server or local)
		if (kind != .Stove)
			return;

		if (RecipeBook.CanCook(currentItem))
		{
			isCooking = true;
			isBurnt = false;
			progress += dt / 4.5f;

			mSizzleTimer -= dt;
			if (mSizzleTimer <= 0.0f)
			{
				mSizzleTimer = 1.5f;
				Audio.PlayOneShot("Audio/sizzle.wav", Transform.Position, 0.45f, .Effects, 1.0f, 20.0f);
			}

			if (progress >= 1.0f)
			{
				currentItem = RecipeBook.CookResult(currentItem);
				progress = 0.0f;
				Audio.PlayOneShot("Audio/ding.wav", Transform.Position, 0.85f, .Effects, 1.0f, 25.0f);
			}
		}
		else if (currentItem == .CookedMeat || currentItem == .CookedSausage)
		{
			isCooking = true;
			// Progress to burning
			progress += dt / 6.0f;

			mSizzleTimer -= dt;
			if (mSizzleTimer <= 0.0f)
			{
				mSizzleTimer = 1.5f;
				Audio.PlayOneShot("Audio/sizzle.wav", Transform.Position, 0.45f, .Effects, 1.0f, 20.0f);
			}

			if (progress >= 1.0f)
			{
				currentItem = .BurntMeat;
				isBurnt = true;
				isCooking = false;
				progress = 0.0f;
				Audio.PlayOneShot("Audio/burn.wav", Transform.Position, 0.95f, .Effects, 1.0f, 30.0f);
			}
		}
		else
		{
			isCooking = false;
			progress = 0.0f;
		}
	}

	private void UpdateVisuals()
	{
		if (Application.Instance.Headless)
			return;

		if (mSelection == null)
		{
			let highlight = Scene.CreateGameObject("Interaction highlight", Transform);
			highlight.Transient = true;
			highlight.Transform.LocalPosition = .(0, 0.025f, 0);
			highlight.Transform.LocalScale = .(1.6f, 0.03f, 1.5f);
			mSelection = highlight.AddComponent<MeshRenderer>();
			mSelection.mesh.Set("builtin:cube");
			mSelection.unlit = true;
		}
		mSelection.color = Player.Local?.FindTargetStation() == this ? Color(1, 0.82f, 0.12f, 1) : Color(0.16f, 0.32f, 0.36f, 1);

		if (currentItem != mLastItem)
		{
			mLastItem = currentItem;
			if (currentItem == .None)
			{
				mItemDisplay?.SetActive(false);
			}
			else
			{
				if (mItemDisplay == null)
				{
					mItemDisplay = Scene.CreateGameObject("StationItem", Transform);
					mItemDisplay.Transient = true;
					mItemDisplay.Transform.LocalPosition = .(0, kind == .Stove ? 1.30f : 1.18f, 0);
					mItemRenderer = mItemDisplay.AddComponent<MeshRenderer>();
				}

				mItemDisplay.SetActive(true);
				let modelPath = RecipeBook.ModelFor(currentItem);
				if (!modelPath.IsEmpty)
				{
					mItemRenderer.mesh.Set(modelPath);
					mItemRenderer.texture.Set(RecipeBook.TextureFor(currentItem));
					if (currentItem == .Bun)
					{
						mItemDisplay.Transform.LocalScale = .(0.55f, 0.20f, 0.55f);
						mItemRenderer.color = .(0.93f, 0.73f, 0.45f, 1.0f);
					}
					else
					{
						mItemDisplay.Transform.LocalScale = .(RecipeBook.DisplayScale(currentItem));
						mItemRenderer.color = RecipeBook.FoodTint(currentItem);
					}
				}
			}
		}

		if (mItemDisplay != null && mItemDisplay.ActiveSelf)
		{
			// Gentle rotation or bobbing for visual delight
			if (isCooking)
			{
				let jitter = (Math.Sin(Time.Time * 30.0f) * 0.02f);
				mItemDisplay.Transform.LocalPosition = .(0, 1.30f + (float)jitter, 0);
			}
			else
			{
				mItemDisplay.Transform.LocalPosition = .(0, kind == .Stove ? 1.30f : 1.18f, 0);
			}
		}
	}

	public void Chop(Player player, float dt)
	{
		if (Game.Instance == null || !Game.Instance.Authority || Game.Instance.phase != 1)
			return;
		if (kind != .CuttingBoard)
			return;

		if (!RecipeBook.CanChop(currentItem))
			return;

		progress += dt / 2.0f;

		mChopAudioTimer -= dt;
		if (mChopAudioTimer <= 0.0f)
		{
			mChopAudioTimer = 0.32f;
			Audio.PlayOneShot("Audio/chop.wav", Transform.Position, 0.7f, .Effects, 1.0f, 20.0f);
		}

		if (progress >= 1.0f)
		{
			currentItem = RecipeBook.ChopResult(currentItem);
			progress = 0.0f;
			Audio.PlayOneShot("Audio/ding.wav", Transform.Position, 0.85f, .Effects, 1.0f, 25.0f);
		}
	}

	public void Interact(Player player)
	{
		if (player == null || Game.Instance == null || !Game.Instance.Authority || Game.Instance.phase != 1)
			return;

		// 1. Trash Can: Discard held item
		if (kind == .TrashCan)
		{
			if (player.heldItem != .None)
			{
				player.heldItem = .None;
				Audio.PlayOneShot("Audio/trash.wav", Transform.Position, 0.8f, .Effects, 1.0f, 25.0f);
			}
			return;
		}

		// 2. Ingredient Crates / Storage
		if (IsCrate(kind))
		{
			if (player.heldItem == .None)
			{
				player.heldItem = ItemFromCrate(kind);
				Audio.PlayOneShot("Audio/pickup.wav", Transform.Position, 0.7f, .Effects, 1.0f, 20.0f);
			}
			return;
		}

		// 3. Serving Hatch: Submit finished dish
		if (kind == .ServingHatch)
		{
			if (player.heldItem != .None)
			{
				if (Game.Instance != null)
				{
					if (Game.Instance.SubmitDish(player.heldItem, player))
					{
						player.heldItem = .None;
					}
					else
					{
						// Keep an unmatched dish so it can be used for a later customer.
						Game.Instance.ShowFeedback("No waiting customer ordered that dish. Keep it or use the trash bin.");
						Audio.PlayOneShot("Audio/defeat.wav", Transform.Position, 0.8f, .Effects, 1.0f, 25.0f);
					}
				}
			}
			return;
		}

		// 4. Counter, Cutting Board, Stove
		if (currentItem == .None && player.heldItem != .None)
		{
			// Check station suitability
			if (kind == .Stove && !RecipeBook.CanCook(player.heldItem) && player.heldItem != .CookedMeat && player.heldItem != .CookedSausage && player.heldItem != .BurntMeat)
				return;
			if (kind == .CuttingBoard && !RecipeBook.CanChop(player.heldItem) && player.heldItem != .SlicedTomato && player.heldItem != .SlicedCheese)
				return;

			// Place item on station
			currentItem = player.heldItem;
			player.heldItem = .None;
			progress = 0.0f;
			isBurnt = (currentItem == .BurntMeat);
			Audio.PlayOneShot("Audio/drop.wav", Transform.Position, 0.7f, .Effects, 1.0f, 20.0f);
		}
		else if (currentItem != .None && player.heldItem == .None)
		{
			// Pick up item from station
			player.heldItem = currentItem;
			currentItem = .None;
			progress = 0.0f;
			isCooking = false;
			isBurnt = false;
			Audio.PlayOneShot("Audio/pickup.wav", Transform.Position, 0.7f, .Effects, 1.0f, 20.0f);
		}
		else if (currentItem != .None && player.heldItem != .None)
		{
			// Attempt ingredient combination
			if (kind == .Counter && RecipeBook.Combine(currentItem, player.heldItem, let combined))
			{
				currentItem = combined;
				player.heldItem = .None;
				progress = 0.0f;
				Audio.PlayOneShot("Audio/ding.wav", Transform.Position, 0.85f, .Effects, 1.0f, 25.0f);
			}
			else
			{
				// Swap items if allowed by station kind
				if (CanAccept(kind, player.heldItem))
				{
					let temp = currentItem;
					currentItem = player.heldItem;
					player.heldItem = temp;
					progress = 0.0f;
					Audio.PlayOneShot("Audio/drop.wav", Transform.Position, 0.7f, .Effects, 1.0f, 20.0f);
				}
			}
		}
	}

	private static bool IsCrate(StationKind k)
	{
		return k == .CrateBun || k == .CrateMeat || k == .CrateSausage ||
		       k == .CrateTomato || k == .CrateCheese;
	}

	private static KitchenItem ItemFromCrate(StationKind k)
	{
		switch (k)
		{
		case .CrateBun: return .Bun;
		case .CrateMeat: return .RawMeat;
		case .CrateSausage: return .RawSausage;
		case .CrateTomato: return .Tomato;
		case .CrateCheese: return .Cheese;
		default: return .None;
		}
	}

	private static bool CanAccept(StationKind k, KitchenItem item)
	{
		if (k == .Stove)
			return RecipeBook.CanCook(item) || item == .CookedMeat || item == .CookedSausage || item == .BurntMeat;
		if (k == .CuttingBoard)
			return RecipeBook.CanChop(item) || item == .SlicedTomato || item == .SlicedCheese;
		if (k == .Counter)
			return true;
		return false;
	}
}
