using System;
using Tessera;

namespace BistroBlitz;

[Component]
public class KitchenCustomers : Component
{
	private GameObject[4] mGuests;
	private int32[4] mRecipes = .(-1, -1, -1, -1);
	private bool[4] mLeaving;
	private bool[4] mHappy;
	private float[4] mWalk;

	private GameObject Part(Transform parent, StringView name, StringView mesh, Vector3 position, Vector3 scale, Color color)
	{
		let part = Scene.CreateGameObject(name, parent);
		part.Transient = true;
		part.Transform.LocalPosition = position;
		part.Transform.LocalScale = scale;
		let renderer = part.AddComponent<MeshRenderer>();
		renderer.mesh.Set(mesh);
		renderer.color = color;
		return part;
	}

	public void ResetCustomers()
	{
		for (int32 i < 4)
		{
			if (mGuests[i] != null) Scene.Destroy(mGuests[i]);
			mGuests[i] = null;
			mRecipes[i] = -1;
			mLeaving[i] = false;
		}
	}

	public override void OnDestroy() { ResetCustomers(); }

	private void Arrive(int32 slot, int32 recipe)
	{
		mRecipes[slot] = recipe;
		mLeaving[slot] = false;
		mHappy[slot] = false;
		let guest = Scene.CreateGameObject(scope $"Customer {slot + 1}");
		guest.Transient = true;
		guest.Transform.Position = .(8, 0, 7.5f + slot * 0.4f);
		mGuests[slot] = guest;
		Color[4] outfits = .(.(0.55f, 0.33f, 0.88f, 1), .(0.94f, 0.62f, 0.16f, 1), .(0.20f, 0.58f, 0.85f, 1), .(0.90f, 0.35f, 0.60f, 1));
		let skin = Color(0.90f - slot * 0.09f, 0.71f - slot * 0.08f, 0.55f - slot * 0.06f, 1);
		Part(guest.Transform, "Customer shirt", "builtin:capsule", .(0, 0.62f, 0), .(0.52f, 0.64f, 0.45f), outfits[slot]);
		Part(guest.Transform, "Customer head", "builtin:sphere", .(0, 1.16f, 0), .(0.42f), skin);
		Part(guest.Transform, "Customer hair", "builtin:sphere", .(0, 1.33f, -0.02f), .(0.44f, 0.22f, 0.42f), .(0.22f, 0.15f, 0.12f, 1));
		Part(guest.Transform, "Left shoe", "builtin:cube", .(-0.16f, 0.11f, 0.05f), .(0.18f, 0.20f, 0.3f), .(0.15f, 0.20f, 0.26f, 1));
		Part(guest.Transform, "Right shoe", "builtin:cube", .(0.16f, 0.11f, 0.05f), .(0.18f, 0.20f, 0.3f), .(0.15f, 0.20f, 0.26f, 1));
		Part(guest.Transform, "Left hand", "builtin:sphere", .(-0.32f, 0.62f, 0), .(0.16f), skin);
		Part(guest.Transform, "Right hand", "builtin:sphere", .(0.32f, 0.62f, 0), .(0.16f), skin);
	}

	public override void Update()
	{
		let game = Game.Instance;
		if (Application.Instance.Headless || game == null) return;
		StepCustomers(Time.DeltaTime);
	}

	public void StepCustomers(float dt)
	{
		let game = Game.Instance;
		for (int32 i < 4)
		{
			let recipe = game.phase == 1 ? game.OrderRecipe(i) : -1;
			if (mGuests[i] == null)
			{
				if (recipe >= 0) Arrive(i, recipe);
				continue;
			}
			if (!mLeaving[i] && (recipe < 0 || recipe != mRecipes[i] || game.OrderOutcome(i) != 0))
			{
				mLeaving[i] = true;
				mHappy[i] = game.OrderOutcome(i) == 1;
			}
			let goal = mLeaving[i] ? Vector3(8, 0, -9) : Vector3(8, 0, 3 - i * 2);
			let delta = goal - mGuests[i].Transform.Position;
			if (delta.Length > 0.06f)
			{
				let distance = Math.Min(delta.Length, dt * 2.8f);
				mGuests[i].Transform.Position += delta.Normalized * distance;
				mWalk[i] += dt * 12;
				mGuests[i].Transform.Rotation = Quaternion.Euler(0, Math.Atan2(delta.x, delta.z) * Mathf.Rad2Deg, (float)Math.Sin(mWalk[i]) * 4);
			}
			else if (mLeaving[i])
			{
				Scene.Destroy(mGuests[i]);
				mGuests[i] = null;
				mRecipes[i] = -1;
			}
			else
			{
				mGuests[i].Transform.Rotation = Quaternion.Euler(0, -90, 0);
			}
		}
	}

	public int32 GuestCount
	{
		get { int32 count = 0; for (let guest in mGuests) if (guest != null) count++; return count; }
	}
	public bool LeavingHappy(int32 slot) => mLeaving[slot] && mHappy[slot];

	public override void OnGUI()
	{
		let game = Game.Instance;
		if (game == null || game.menu || game.phase != 1 || game.camera == null) return;
		for (int32 i < 4)
		{
			if (mGuests[i] == null) continue;
			let label = scope $"{i + 1}";
			if (mLeaving[i]) label.Set(mHappy[i] ? ":)" : ":(");
			game.WorldLabel(mGuests[i].Transform.Position + Vector3(0, 1.8f, 0), label,
				mLeaving[i] && !mHappy[i] ? Color(1, 0.5f, 0.35f, 1) : Color(0.6f, 1, 0.8f, 1), 28);
		}
	}
}
