# EEG Topoplots

The `eeg_topoplot` recipe adds a bit of convenience for plotting Topoplots from EEG data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as [`topoplot`](@ref).


```@docs
TopoPlots.eeg_topoplot
```



So for the standard 10/20 montage, one can drop the `positions` attribute:
```@example 1
using TopoPlots, CairoMakie

labels = TopoPlots.CHANNELS_10_20
TopoPlots.eeg_topoplot(rand(19), labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))
```

If the channels aren't 10/20, one can still plot them, but then the positions need to be passed as well:

```@example 1
data, positions = TopoPlots.example_data()
labels = ["s$i" for i in 1:size(data, 1)]
TopoPlots.eeg_topoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))
```

```docs
TopoPlots.example_data
```
