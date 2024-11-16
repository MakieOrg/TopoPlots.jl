# EEG Topoplots

The `eeg_topoplot` recipe adds a bit of convenience for plotting Topoplots from EEG data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as [`topoplot`](@ref).


```@docs
TopoPlots.eeg_topoplot
```



For the standard 10/20 (or 10/05) montage, one can drop the `positions` attribute:
```@example eeg
using TopoPlots, CairoMakie

labels = TopoPlots.CHANNELS_10_05 # TopoPlots.CHANNELS_10_20 contains the 10/20 subset

f,ax,h = TopoPlots.eeg_topoplot(rand(348); labels=labels, axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=2, strokewidth=2,),colorrange=[-5,5])

```


If the channels aren't 10/05, one can still plot them, but then the positions need to be passed as well:

```@example eeg
data, positions = TopoPlots.example_data()
labels = ["s$i" for i in 1:size(data, 1)]
TopoPlots.eeg_topoplot(data[:, 340, 1]; labels, label_text = true, positions=positions, axis=(aspect=DataAspect(),))
```

## Subset of channels
If you only ask to plot a subset of channels, we highly recommend to define your bounding geometry yourself. We follow MNE functionality and normalize the positions prior to interpolation / plotting. If you only use a subset of channels, the positions will be relative to each other, not at absolute coordinates.

```@example eeg
f = Figure()
ax1 = f[1,1] = Axis(f;aspect=DataAspect())
ax2 = f[1,2] = Axis(f;aspect=DataAspect())
kwlist = (;label_text=true,label_scatter=(markersize=10, strokewidth=2,color=:white))
TopoPlots.eeg_topoplot!(ax1,[1,0.5,0]; labels=["Cz","Fz","Fp1"],kwlist...)
TopoPlots.eeg_topoplot!(ax2,[1,0.5,05]; labels=["Cz","Fz","Fp1"], bounding_geometry=Circle(Point2f(0.5,0.5), 0.5),kwlist...)

f
```
As visible in the left plot, the positions are normalized to the bounding geometry. The right plot shows the same data, but with Cz correctly centered.

## Example data

```@docs
TopoPlots.example_data
```
