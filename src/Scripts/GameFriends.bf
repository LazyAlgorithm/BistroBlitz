using System;
using System.Collections;
using Tessera;

namespace BistroBlitz;

extension Game
{
	public String friendBrowserTitle = new .() ~ delete _;
	public String friendBrowserStatus = new .() ~ delete _;
	public String friendSelectedName = new .() ~ delete _;
	public String friendHelp = new .() ~ delete _;
	public String friendActionLabel = new .() ~ delete _;

	private List<uint64> mFriendIds = new .() ~ delete _;
	public bool mInvitingFriends;
	private int32 mFriendPage = 0;
	private int32 mFriendSelection = -1;
	private float mFriendRefresh = 0.0f;

	public void RefreshFriends()
	{
		mFriendIds.Clear();
		mFriendRefresh = 3.0f;

		if (!Steam.IsReady)
			return;

		for (int32 i < (int32)Steam.FriendCount)
		{
			let id = Steam.FriendAt(i);
			if (mInvitingFriends)
			{
				if (Steam.FriendOnline(id))
					mFriendIds.Add(id);
			}
			else
			{
				let room = scope String();
				Steam.FriendPresence(id, "bistro_blitz_room", room);
				if (!room.IsEmpty)
					mFriendIds.Add(id);
			}
		}

		mFriendPage = Math.Clamp(mFriendPage, 0, Math.Max(0, ((int32)mFriendIds.Count - 1) / 6));
		if (mFriendSelection >= mFriendIds.Count)
			mFriendSelection = -1;
	}

	public void UpdateFriendBrowser()
	{
		let joinRequest = scope String();
		if (Steam.TakeJoinRequest(joinRequest))
		{
			OnLeave();
			address.Set(joinRequest);
			OnJoin();
		}
		mFriendRefresh -= Time.UnscaledDeltaTime;
		if (mFriendRefresh <= 0)
			RefreshFriends();

		friendBrowserTitle.Set(mInvitingFriends ? "INVITE CHEF FRIENDS" : "FRIENDS HOSTING BISTRO BLITZ");
		friendBrowserStatus.Set(!Steam.IsReady ? "Steam is offline. Sign in to Steam to find friends." : (mFriendIds.Count == 0 ? (mInvitingFriends ? "No online friends available." : "No friends are hosting a kitchen right now.") : scope $"{mFriendIds.Count} FRIEND(S)  |  PAGE {mFriendPage + 1}"));

		friendSelectedName.Set("SELECT A FRIEND");
		if (mFriendSelection >= 0 && mFriendSelection < mFriendIds.Count)
			Steam.FriendName(mFriendIds[mFriendSelection], friendSelectedName);

		friendActionLabel.Set(mInvitingFriends ? "SEND INVITATION" : "JOIN KITCHEN");
		friendHelp.Set(mInvitingFriends ? "Select a friend and send a Steam invitation to cook together." : "Select a friend hosting Bistro Blitz, then join their kitchen.");

		if (mMenu == null)
			return;

		for (int32 row < 6)
		{
			if (let button = mMenu.Find(scope $"friend{row}"))
			{
				let index = mFriendPage * 6 + row;
				button.visible = index < mFriendIds.Count;
				if (index < mFriendIds.Count)
				{
					let name = scope String();
					Steam.FriendName(mFriendIds[index], name);
					button.SetText(scope $"{(index == mFriendSelection ? "> " : "")}{name}  ({(mInvitingFriends ? "ONLINE" : "COOKING")})");
				}
			}
		}
	}

	public void OnInviteFriends()
	{
		if (!Connected || Scene.Network.Transport != .Steam || !Steam.IsReady)
		{
			notice.Set("Create a Steam kitchen lobby before inviting friends.");
			return;
		}

		mReturnPage = mPage;
		mInvitingFriends = true;
		mFriendPage = 0;
		mFriendSelection = -1;
		notice.Clear();
		RefreshFriends();
		OpenPage(.Friends);
	}

	public void OnFriendSelected(UIElement element)
	{
		if (element == null || !element.Id.StartsWith("friend"))
			return;

		let index = mFriendPage * 6 + SceneSerializer.ParseInt(element.Id.Substring(6));
		if (index >= 0 && index < mFriendIds.Count)
			mFriendSelection = index;
	}

	public void OnRefreshFriends()
	{
		RefreshFriends();
	}

	public void OnPreviousFriends()
	{
		mFriendPage = Math.Max(0, mFriendPage - 1);
	}

	public void OnNextFriends()
	{
		mFriendPage = Math.Min(Math.Max(0, ((int32)mFriendIds.Count - 1) / 6), mFriendPage + 1);
	}

	public void OnFriendAction()
	{
		if (!Steam.IsReady || mFriendSelection < 0 || mFriendSelection >= mFriendIds.Count)
		{
			notice.Set("Select a Steam friend first.");
			return;
		}

		let id = mFriendIds[mFriendSelection];
		if (!Steam.IsFriend(id))
		{
			RefreshFriends();
			notice.Set("Friend is no longer available.");
			return;
		}

		if (mInvitingFriends)
		{
			if (!Connected || Scene.Network.Transport != .Steam)
			{
				notice.Set("Steam lobby is no longer active.");
				return;
			}

			let connect = scope String();
			if (Authority)
				connect.AppendF("{}", Steam.UserId);
			else
				connect.Set(address);

			notice.Set(Steam.Invite(id, connect) ? "Steam invitation sent!" : "Could not send invitation.");
		}
		else
		{
			let connect = scope String();
			Steam.FriendPresence(id, "bistro_blitz_room", connect);
			if (uint64.Parse(connect).GetValueOrDefault() == 0)
			{
				notice.Set("That friend is no longer hosting.");
				RefreshFriends();
				return;
			}

			address.Set(connect);
			OnJoin();
		}
	}
}
