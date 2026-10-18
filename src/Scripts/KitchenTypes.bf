using System;
using Tessera;

namespace BistroBlitz;

public enum KitchenItem : int32
{
	None = 0,
	Plate,
	Bun,
	RawMeat,
	CookedMeat,
	BurntMeat,
	RawSausage,
	CookedSausage,
	Tomato,
	SlicedTomato,
	Cheese,
	SlicedCheese,
	Burger,
	Cheeseburger,
	DeluxeBurger,
	HotDog,
	Salad,
	Pizza
}

public enum StationKind : int32
{
	Counter = 0,
	CuttingBoard,
	Stove,
	CrateBun,
	CrateMeat,
	CrateSausage,
	CrateTomato,
	CrateCheese,
	CratePlate,
	ServingHatch,
	TrashCan
}

public struct Recipe
{
	public StringView name;
	public KitchenItem resultItem;
	public int32 points;
	public float timeLimit;
	public StringView description;

	public this(StringView name, KitchenItem result, int32 points, float time, StringView desc)
	{
		this.name = name;
		this.resultItem = result;
		this.points = points;
		this.timeLimit = time;
		this.description = desc;
	}
}

public static class RecipeBook
{
	public static readonly Recipe[] AllRecipes = new Recipe[] (
		.("Classic Burger", .Burger, 150, 60.0f, "Bun + Cooked Patty"),
		.("Cheeseburger", .Cheeseburger, 200, 70.0f, "Bun + Cooked Patty + Cheese"),
		.("Deluxe Burger", .DeluxeBurger, 260, 80.0f, "Bun + Patty + Cheese + Tomato"),
		.("Hot Dog", .HotDog, 140, 50.0f, "Bun + Cooked Sausage"),
		.("Fresh Salad", .Salad, 180, 55.0f, "Sliced Tomato + Sliced Cheese")
	);

	public static StringView ItemName(KitchenItem item)
	{
		switch (item)
		{
		case .None: return "Empty";
		case .Plate: return "Plate";
		case .Bun: return "Burger Bun";
		case .RawMeat: return "Raw Patty";
		case .CookedMeat: return "Cooked Patty";
		case .BurntMeat: return "Burnt Patty (Trash!)";
		case .RawSausage: return "Raw Sausage";
		case .CookedSausage: return "Cooked Sausage";
		case .Tomato: return "Fresh Tomato";
		case .SlicedTomato: return "Sliced Tomato";
		case .Cheese: return "Cheese Block";
		case .SlicedCheese: return "Sliced Cheese";
		case .Burger: return "Classic Burger";
		case .Cheeseburger: return "Cheeseburger";
		case .DeluxeBurger: return "Deluxe Burger";
		case .HotDog: return "Hot Dog";
		case .Salad: return "Fresh Salad";
		case .Pizza: return "Pizza";
		}
	}

	public static StringView ModelFor(KitchenItem item)
	{
		switch (item)
		{
		case .None: return "";
		case .Plate: return "Models/plate.glb";
		case .Bun: return "builtin:cylinder";
		case .RawMeat: return "Models/meat-raw.glb";
		case .CookedMeat: return "Models/meat-patty.glb";
		case .BurntMeat: return "Models/meat-cooked.glb";
		case .RawSausage: return "Models/hot-dog-raw.glb";
		case .CookedSausage: return "Models/hot-dog-raw.glb";
		case .Tomato: return "Models/tomato.glb";
		case .SlicedTomato: return "Models/tomato-slice.glb";
		case .Cheese: return "Models/cheese.glb";
		case .SlicedCheese: return "Models/cheese.glb";
		case .Burger: return "Models/burger.glb";
		case .Cheeseburger: return "Models/burger-cheese.glb";
		case .DeluxeBurger: return "Models/burger-cheese.glb";
		case .HotDog: return "Models/hot-dog.glb";
		case .Salad: return "Models/salad.glb";
		case .Pizza: return "Models/pizza.glb";
		}
	}

	public static Color FoodTint(KitchenItem item)
	{
		if (item == .BurntMeat) return .(0.10f, 0.08f, 0.06f, 1);
		if (item == .CookedSausage) return .(0.62f, 0.40f, 0.22f, 1);
		return .White;
	}

	public static StringView TextureFor(KitchenItem item)
	{
		return item == .None || item == .Bun ? "" : "Models/Textures/colormap.png";
	}

	public static float DisplayScale(KitchenItem item)
	{
		switch (item)
		{
		case .Tomato, .SlicedTomato: return 3.5f;
		case .Burger, .Cheeseburger, .DeluxeBurger: return 1.8f;
		case .Cheese, .SlicedCheese: return 1.8f;
		case .CookedMeat: return 2.6f;
		case .RawMeat, .BurntMeat: return 1.7f;
		case .RawSausage, .CookedSausage: return 1.6f;
		case .Plate: return 1.12f;
		default: return 1.35f;
		}
	}

	public static bool CanChop(KitchenItem item)
	{
		return item == .Tomato || item == .Cheese;
	}

	public static KitchenItem ChopResult(KitchenItem item)
	{
		switch (item)
		{
		case .Tomato: return .SlicedTomato;
		case .Cheese: return .SlicedCheese;
		default: return item;
		}
	}

	public static bool CanCook(KitchenItem item)
	{
		return item == .RawMeat || item == .RawSausage;
	}

	public static KitchenItem CookResult(KitchenItem item)
	{
		switch (item)
		{
		case .RawMeat: return .CookedMeat;
		case .RawSausage: return .CookedSausage;
		default: return item;
		}
	}

	public static bool IsFinishedDish(KitchenItem item)
	{
		return item == .Burger || item == .Cheeseburger || item == .DeluxeBurger || item == .HotDog || item == .Salad || item == .Pizza;
	}

	public static bool Combine(KitchenItem a, KitchenItem b, out KitchenItem result)
	{
		result = .None;
		// Check both orders (a, b) and (b, a)
		if (TryCombinePair(a, b, out result)) return true;
		if (TryCombinePair(b, a, out result)) return true;
		return false;
	}

	private static bool TryCombinePair(KitchenItem primary, KitchenItem secondary, out KitchenItem result)
	{
		result = .None;

		// Burger assembly: Bun + CookedMeat -> Burger
		if (primary == .Bun && secondary == .CookedMeat)
		{
			result = .Burger;
			return true;
		}

		// Cheeseburger assembly: Burger + Cheese / SlicedCheese -> Cheeseburger
		if (primary == .Burger && (secondary == .Cheese || secondary == .SlicedCheese))
		{
			result = .Cheeseburger;
			return true;
		}

		// Deluxe burger: Cheeseburger + Tomato / SlicedTomato -> DeluxeBurger
		if (primary == .Cheeseburger && (secondary == .Tomato || secondary == .SlicedTomato))
		{
			result = .DeluxeBurger;
			return true;
		}

		// Hot Dog: Bun + CookedSausage -> HotDog
		if (primary == .Bun && secondary == .CookedSausage)
		{
			result = .HotDog;
			return true;
		}

		// Fresh Salad: SlicedTomato + SlicedCheese -> Salad
		if (primary == .SlicedTomato && (secondary == .SlicedCheese || secondary == .Cheese))
		{
			result = .Salad;
			return true;
		}

		// Plating: Plate + Finished Dish -> Plated Dish
		if (primary == .Plate && IsFinishedDish(secondary))
		{
			result = secondary;
			return true;
		}

		return false;
	}
}
