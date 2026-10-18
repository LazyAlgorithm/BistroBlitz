using System;
using Tessera;

namespace BistroBlitz;

extension KitchenStation
{
	private MeshRenderer mBurner;
	private GameObject[3] mSteam;
	private MeshRenderer[3] mSteamRenderers;

	private void UpdateStoveEffects()
	{
		if (kind != .Stove || Application.Instance.Headless) return;
		if (mBurner == null)
		{
			let burner = Scene.CreateGameObject("Visible stove heat", Transform);
			burner.Transient = true;
			burner.Transform.LocalPosition = .(0, 1.075f, 0);
			burner.Transform.LocalScale = .(1.12f, 0.035f, 1.12f);
			mBurner = burner.AddComponent<MeshRenderer>();
			mBurner.mesh.Set("builtin:cylinder");
			mBurner.unlit = true;
			for (int32 i < 3)
			{
				let puff = Scene.CreateGameObject("Cooking steam", Transform);
				puff.Transient = true;
				mSteam[i] = puff;
				let renderer = puff.AddComponent<MeshRenderer>();
				renderer.mesh.Set("builtin:sphere");
				renderer.castShadows = false;
				mSteamRenderers[i] = renderer;
			}
		}
		let cooked = currentItem == .CookedMeat || currentItem == .CookedSausage;
		mBurner.color = isCooking ? (cooked ? Color(1, 0.64f, 0.12f, 1) : Color(1, 0.26f, 0.05f, 1)) : Color(0.10f, 0.14f, 0.17f, 1);
		for (int32 i < 3)
		{
			mSteam[i].SetActive(isCooking || isBurnt);
			let cycle = Time.Time * 0.65f + i / 3.0f;
			let rise = cycle - (float)Math.Floor(cycle);
			let offset = (i - 1) * 0.24f;
			mSteam[i].Transform.LocalPosition = .(offset + (float)Math.Sin(Time.Time * 2 + i) * 0.06f, 1.6f + rise * 0.75f, 0.15f);
			mSteam[i].Transform.LocalScale = .(0.07f + rise * 0.12f);
			mSteamRenderers[i].color = isBurnt ? Color(0.18f, 0.20f, 0.22f, 1) : Color(0.82f, 0.91f, 0.96f, 1);
		}
	}
}
