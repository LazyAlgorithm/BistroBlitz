using System;
using Tessera.Editor;

namespace BistroBlitz;

class Program
{
	public static int Main(String[] args)
	{
		GameSetup.Register();
		return EditorMain.Run(args);
	}
}
