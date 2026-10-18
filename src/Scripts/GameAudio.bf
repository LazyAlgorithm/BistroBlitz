using System;
using Tessera;

namespace BistroBlitz;

extension Game
{
	private AudioSource mMusicSource;
	private String mHoveredAudio = new .() ~ delete _;
	private int32 mAudioPhase = -1;

	public void InitializeAudio()
	{
		ApplyAudioVolumes();
		if (Application.Instance.Headless)
			return;

		mMusicSource = GameObject.AddComponent<AudioSource>();
		mMusicSource.localOnly = true;
		mMusicSource.audioClip.Set("Audio/music.wav");
		mMusicSource.group = .Music;
		mMusicSource.loop = true;
		mMusicSource.spatial = false;
		mMusicSource.playOnStart = false;
		mMusicSource.volume = 1.0f;
	}

	public void ApplyAudioVolumes()
	{
		Audio.MasterVolume = masterVolume;
		Audio.SetGroupVolume(.Music, musicVolume);
		Audio.SetGroupVolume(.Effects, effectsVolume);
		Audio.SetGroupVolume(.Interface, effectsVolume);
		Audio.SetGroupVolume(.Ambience, masterVolume * 0.7f);
	}

	public void UpdateAudio()
	{
		if (Application.Instance.Headless)
			return;

		if (mAudioPhase != phase)
		{
			mAudioPhase = phase;
			if (phase == 0 || phase == 1)
			{
				mMusicSource?.Play();
			}
			else if (phase == 2)
			{
				// Results
				mMusicSource?.Play();
			}
		}
	}

	public void MenuAudio()
	{
		if (!menu || mMenu == null)
		{
			mHoveredAudio.Clear();
			return;
		}

		var element = mMenu.Hovered;
		while (element != null && element.tag != "button")
			element = element.parent;

		if (element == null)
		{
			mHoveredAudio.Clear();
			return;
		}

		let key = scope $"{mPage}/{element.attributes.Get("onclick")}/{element.Id}/{element.text}";
		if (mHoveredAudio != key)
		{
			Audio.PlayOneShot2D("Audio/hover.wav", 0.6f, .Interface);
		}
		mHoveredAudio.Set(key);

		if (Input.GetMouseButtonDown(0))
		{
			if (element.attributes.Get("onclick") == "OnBack")
				Audio.PlayOneShot2D("Audio/back.wav", 0.8f, .Interface);
			else
				Audio.PlayOneShot2D("Audio/click.wav", 0.8f, .Interface);
		}
	}
}
