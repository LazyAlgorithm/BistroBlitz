using System;
using Tessera;

namespace BistroBlitz;

static class GameSetup
{
	public static void Register()
	{
		GameWindow.EscapeQuits = false;
		GameWindow.StartsFullscreen = true;
		let mute = scope String();
		if (Environment.GetEnvironmentVariable("BISTRO_MUTE", mute) case .Ok && mute == "1")
			Audio.NoDevice = true;

		NetworkManager.RegisterPrefab("Player", new (scene) => Prefab.Create(scene, "Prefabs/Player.tprefab"));
	}
}
