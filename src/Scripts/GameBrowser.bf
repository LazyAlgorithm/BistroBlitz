using System;
using Tessera;

namespace BistroBlitz;

extension Game
{
	private bool mBrowserConnecting;
	private bool mBrowserJoined;
	private float mBrowserWait;

	private bool PrepareRoomCode()
	{
		var code = StringView(address);
		let at = code.IndexOf("join=");
		if (at >= 0) code = code.Substring(at + 5);
		let end = code.IndexOf('&');
		if (end >= 0) code = code.Substring(0, end);
		let clean = scope String();
		for (let c in code.RawChars)
			if (c.IsLetterOrDigit) clean.Append(c.ToUpper);
		address.Set(clean);
		if (!clean.IsEmpty) return true;
		notice.Set("Enter the host's room code or invitation link.");
		return false;
	}

	public void OnPasteRoom()
	{
		WebPlatform.PromptText("Room code or invitation link", address);
	}

	public void OnShareRoom()
	{
		let link = scope String();
		WebRtc.GetJoinLink(link);
		if (link.IsEmpty) { notice.Set("Create a browser room first."); return; }
		if (WebPlatform.IsTouchDevice) WebPlatform.ShareText("Join my Bistro Blitz kitchen", link);
		else WebPlatform.CopyText(link);
		notice.Set(scope $"Room {WebRtc.RoomCode}: invitation link ready to share.");
	}

	private void UpdateBrowserConnection()
	{
		if (!WebPlatform.IsWeb) return;
		let net = Scene.Network;
		if (net == null || !net.IsClient) { mBrowserJoined = false; return; }
		if (net.IsConnected) { mBrowserConnecting = false; mBrowserJoined = true; return; }
		if (mBrowserConnecting)
		{
			mBrowserWait += Time.DeltaTime;
			WebRtc.GetStatus(notice);
			if (mBrowserWait < 40) return;
		}
		else if (!mBrowserJoined) return;
		let reason = scope String();
		WebRtc.GetStatus(reason);
		OnLeave();
		notice.Set(reason.IsEmpty ? "The host could not be reached. Check the room code and try again." : reason);
	}
}
