# Art assets

The existing project models are from Kenney Food Kit and Furniture Kit (CC0). Food Kit models reference `Textures/colormap.png` relative to their GLB file. The original import omitted that texture. It is now installed at `src/Models/Textures/colormap.png` and explicitly assigned to static, held and counter food renderers, because Tessera static MeshRenderer requires an explicit albedo texture.

The palette was restored from the same [Kenney asset mirror](https://github.com/shorepine/kenney/blob/main/3d/food/Textures/colormap.png). Its Git blob SHA is `1dfac9e6c4639266b629ad4c43e3048c2117d520`. The mirror burger model and existing burger model match exactly (`6917839cef7255164856221a0dc43d3ff9e62a3d`), confirming that the palette accompanies this model version. Original creator: [Kenney](https://kenney.nl/). No new generated bitmap art was used.

The kitchen scene is built by `tools/build_scene.py` using the original models and simple colored geometry. Code generated chefs and customers use built-in primitives. Audio was synthesized locally by `tools/generate_audio.py`.
