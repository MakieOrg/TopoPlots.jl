# EEG Topoplots

The `eeg_topoplot` recipe adds a bit of convience for plotting Topoplots from eeg data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as [`topoplot`](@ref).


```@docs
TopoPlots.eeg_topoplot
```



So for the standard 10/20 montage, one can drop the `positions` attribute:
```@example 1
using TopoPlots, CairoMakie

labels = TopoPlots.CHANNELS_10_20
TopoPlots.eeg_topoplot(rand(19), labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))
```

If the channels aren't 10/20, one can still plot them, but then the positions need to get passed as well:

```@example 1

data = Array{Float32}(undef, 64, 400, 3)
read!(TopoPlots.assetpath("example-data.bin"), data)
positions = Vector{Point2f}(undef, 64)
read!(TopoPlots.assetpath("layout64.bin"), positions)
labels = ["s$i" for i in 1:size(data, 1)]
TopoPlots.eeg_topoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))
```
