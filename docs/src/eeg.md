# EEG Topoplots

The `eeg_topoplot` recipe adds a bit of convenience for plotting Topoplots from EEG data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as [`topoplot`](@ref).


```@docs
TopoPlots.eeg_topoplot
```



So for the standard 10/20 montage, one can drop the `positions` attribute:
```@example 1
using TopoPlots, CairoMakie, DataFrames

labels = TopoPlots.CHANNELS_10_20

TopoPlots.eeg_topoplot(rand(19), labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))
```

If the channels aren't 10/20, one can still plot them, but then the positions need to be passed as well:

```@example 1

data, positions = TopoPlots.example_data()
labels = ["s$i" for i in 1:size(data, 1)]
TopoPlots.eeg_topoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))
```


## EEG Topoplot Series
The `eeg_topoplot_series` function leverages AlgebraOfGraphics.jl to plot a series of topographies.



```@docs
TopoPlots.eeg_topoplot_series
```


The function supports plotting data-matrices
```@example 1
data, positions = TopoPlots.example_data()
TopoPlots.eeg_topoplot_series(data[:, :, 1],40, topoplotCfg=(positions=positions,))
```

But you might want to use the DataFrames interface. This allows to specify the bin-widths of each topoplot (`Δbin`) in time instead of samples

```@example 1

  df = DataFrame(data[:,:,1]',labels)
  df[!,:time] .= range(start=-0.3,step=1/500,length=size(data,2))
  df = stack(df,Not([:time]),variable_name=:label,value_name="erp")

  first(df,3)
```

This allows to run:
```@example 1
# 100ms bins
TopoPlots.eeg_topoplot_series(df,0.1, topoplotCfg=(positions=positions,))
```

We can also provide a figure

```@docs
TopoPlots.eeg_topoplot_series!
```

```@example 1
f = Figure()
TopoPlots.eeg_topoplot_series!(f[1,1],df,0.3, topoplotCfg=(positions=positions,))
TopoPlots.eeg_topoplot_series!(f[2,1],df,0.1, topoplotCfg=(positions=positions,))
```