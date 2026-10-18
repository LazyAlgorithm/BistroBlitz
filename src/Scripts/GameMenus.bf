using System;
using Tessera;

namespace BistroBlitz;

public enum MenuPage
{
	Main,
	Host,
	Join,
	Friends,
	Settings,
	Results
}

extension Game
{
	public MenuPage mPage = .Main;
	public MenuPage mReturnPage = .Main;

	public float masterVolume = 0.8f;
	public float musicVolume = 0.6f;
	public float effectsVolume = 0.8f;
	public float fieldOfView = 60.0f;
	public String settingsLabel = new .() ~ delete _;

	public void InitializeMenus()
	{
		if (mMenu == null)
			return;

		mMenu.referenceWidth = 1920;
		mMenu.referenceHeight = 1080;
		settingsLabel.Set("Graphics & Audio Configured");
		ApplyAudioVolumes();
		OpenPage(.Main);
	}

	public void OpenPage(MenuPage page)
	{
		TouchControls.Shown = false;
		mPage = page;
		menu = true;

		if (mMenu == null)
			return;

		mMenu.Enabled = true;
		if (mHud != null)
			mHud.Enabled = (phase == 1 && !menu);

		StringView file = "menu";
		switch (page)
		{
		case .Main: file = "menu";
		case .Host: file = "host";
		case .Join: file = "join";
		case .Friends: file = "friends";
		case .Settings: file = "settings";
		case .Results: file = "results";
		}

		mMenu.document.Set(scope $"UI/{file}.tui");
		if (WebPlatform.IsWeb && !MobileVersion && (page == .Host || page == .Join))
			mMenu.document.Set(scope $"UI/web/{file}.tui");
		mMenu.Reload();
		UpdateMenuEntries();
	}

	private void UpdateMenuEntries()
	{
		if (mMenu == null) return;
		if (let entry = mMenu.Find("steamEntry")) entry.visible = !WebPlatform.IsWeb;
		if (let entry = mMenu.Find("quitEntry")) entry.visible = !WebPlatform.IsWeb;
		if (let entry = mMenu.Find("shareEntry")) entry.visible = WebPlatform.IsWeb && Connected && Authority;
		if (let entry = mMenu.Find("resumeEntry")) entry.visible = phase == 1;
		if (let entry = mMenu.Find("leaveEntry")) entry.visible = phase != 0 || Connected;
		if (let entry = mMenu.Find("inviteEntry")) entry.visible = Connected && Scene.Network.Transport == .Steam;
	}

	public void EscapeMenu()
	{
		if (!menu && phase == 1)
		{
			OpenPage(.Main);
		}
		else if (menu && phase == 1)
		{
			OnResume();
		}
		else if (mPage != .Main)
		{
			OnBack();
		}
		else
		{
			OnQuit();
		}
	}

	public void OnQuickPlay()
	{
		if (Connected) { notice.Set("Leave the current kitchen before starting solo."); return; }
		notice.Clear();
		StartMatch();
	}

	public void OnHostMenu()
	{
		mReturnPage = mPage;
		notice.Clear();
		OpenPage(.Host);
	}

	public void OnJoinMenu()
	{
		mReturnPage = mPage;
		notice.Clear();
		mInvitingFriends = false;
		OpenPage(.Join);
	}

	public void OnFriendsMenu()
	{
		mReturnPage = mPage;
		notice.Clear();
		mInvitingFriends = false;
		RefreshFriends();
		OpenPage(.Friends);
	}

	public void OnSettingsMenu()
	{
		mReturnPage = mPage;
		notice.Clear();
		OpenPage(.Settings);
	}

	public void OnBack()
	{
		notice.Clear();
		let back = mReturnPage;
		mReturnPage = .Main;
		OpenPage(back);
	}

	public void OnResume()
	{
		if (phase == 1)
		{
			menu = false;
			if (mMenu != null)
				mMenu.Enabled = false;
			if (mHud != null)
				mHud.Enabled = true;
		}
		else
		{
			OpenPage(.Main);
		}
	}

	public void OnRestartGame()
	{
		StartMatch();
	}

	public void OnQuit()
	{
		Application.Instance.Running = false;
	}

	public void OnFullscreen()
	{
		GameWindow.ToggleFullscreen();
	}

	public void OnMasterVolume(UIElement element)
	{
		masterVolume = Math.Clamp(element.value, 0.0f, 1.0f);
		ApplyAudioVolumes();
	}

	public void OnMusicVolume(UIElement element)
	{
		musicVolume = Math.Clamp(element.value, 0.0f, 1.0f);
		ApplyAudioVolumes();
	}

	public void OnEffectsVolume(UIElement element)
	{
		effectsVolume = Math.Clamp(element.value, 0.0f, 1.0f);
		ApplyAudioVolumes();
	}

	public void OnFov(UIElement element)
	{
		fieldOfView = Math.Clamp(element.value, 40.0f, 90.0f);
		if (camera != null)
			camera.orthographicSize = Math.Clamp(fieldOfView * 0.14f, 7.8f, 11.2f);
	}

	public void OnAddressChanged(UIElement element)
	{
		if (element != null && !element.text.IsEmpty)
			address.Set(element.text);
	}

	public void OnPortChanged(UIElement element)
	{
		if (element != null && !element.text.IsEmpty)
			portText.Set(element.text);
	}
}
