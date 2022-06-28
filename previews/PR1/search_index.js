var documenterSearchIndex = {"docs":
[{"location":"functions/#Function-Reference","page":"Function reference","title":"Function Reference","text":"","category":"section"},{"location":"functions/","page":"Function reference","title":"Function reference","text":"TopoPlots.enclosing_geometry\nTopoPlots.labels2positions","category":"page"},{"location":"functions/#TopoPlots.enclosing_geometry","page":"Function reference","title":"TopoPlots.enclosing_geometry","text":"enclosing_geometry(G::Type{<: Geometry}, positions, enlarge=0.0)\n\nReturns the Geometry of Type G, that best fits all positions. The Geometry can be enlarged by 1.x, so e.g. enclosing_geometry(Circle, positions, 0.1) will return a Circle that encloses all positions with a padding of 10%.\n\n\n\n\n\n","category":"function"},{"location":"functions/#TopoPlots.labels2positions","page":"Function reference","title":"TopoPlots.labels2positions","text":"labels2positions(labels)\n\nCurrently only supports 10/20 layout, by looking it up in TopoPlots.CHANNEL_TO_POSITION_10_20.\n\n\n\n\n\n","category":"function"},{"location":"functions/","page":"Function reference","title":"Function reference","text":"TopoPlots.pad_boundary!","category":"page"},{"location":"functions/#TopoPlots.pad_boundary!","page":"Function reference","title":"TopoPlots.pad_boundary!","text":"pad_boundary(::Type{Geometry}, positions, enlarge=0.2) where Geometry\n\nAdds new points to positions, adding the boundary from enclosing all positions with Geometry. See TopoPlots.enclosing_geometry for more details about the boundary.\n\n\n\n\n\n","category":"function"},{"location":"general/#Recipe-for-General-TopoPlots","page":"General TopoPlots","title":"Recipe for General TopoPlots","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"At the core of TopoPlots.jl is the topoplot recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.topoplot","category":"page"},{"location":"general/#TopoPlots.topoplot","page":"General TopoPlots","title":"TopoPlots.topoplot","text":"topoplot(data::Vector{<:Real}, positions::Vector{<: Point2})\n\nCreates an irregular interpolation for each data[i] point at positions[i].\n\nAttributes\n\ncolormap = Reverse(:RdBu)\ncolorrange = automatic\nlabels::Vector{<:String} = nothing: names for each data point\ninterpolation::Interpolator = ClaughTochter(): Applicable interpolators are TopoPlots.ClaughTochter, TopoPlots.DelaunayMesh, TopoPlots.SplineInterpolator\nbounding_geometry = Circle: the geometry added to the points, to create a smooth boundary. Can be Rect or Circle.\npadding = 0.1: padding applied to bounding_geometry\npad_value = 0.0: data value filled in for each added position from bounding_geometry\nresolution = (512, 512): resolution of the interpolation\nlabel_text = nothing:\ntrue: add text plot for each position from labels\nNamedTuple: Attributes get passed to the Makie.text! call.\nlabel_scatter = nothing:\ntrue: add point for each position with\nNamedTuple: Attributes get passed to the Makie.scatter! call.\ncontours = nothing:\ntrue: add point for each position\nNamedTuple: Attributes get passed to the Makie.contour! call.\n\nExample\n\nusing TopoPlots, CairoMakie\ntopoplot(rand(10), rand(Point2f, 10); contours=(color=:red, linewidth=2))\n\n\n\n\n\n","category":"function"},{"location":"general/#Interpolators","page":"General TopoPlots","title":"Interpolators","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The recipe supports different interpolation methods, namely:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.DelaunayMesh\nTopoPlots.ClaughTochter\nTopoPlots.SplineInterpolator","category":"page"},{"location":"general/#TopoPlots.DelaunayMesh","page":"General TopoPlots","title":"TopoPlots.DelaunayMesh","text":"DelaunayMesh()\n\nCreates a delaunay triangulation of the points and linearly interpolates between the vertices of the triangle. Really fast interpolation that happens on the GPU (for GLMakie), so optimal for exploring larger timeseries.\n\nwarning: Warning\nDelaunayMesh won't allow you to add a contour plot to the topoplot.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.ClaughTochter","page":"General TopoPlots","title":"TopoPlots.ClaughTochter","text":"ClaughTochter(fill_value=NaN, tol=1e-6, maxiter=400, rescale=false)\n\nPiecewise cubic, C1 smooth, curvature-minimizing interpolant in 2D. Find more detailed docs in SciPy.interpolate.CloughTocher2DInterpolator. Slow, but yields the smoothest interpolation.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.SplineInterpolator","page":"General TopoPlots","title":"TopoPlots.SplineInterpolator","text":"SplineInterpolator(;kx=2, ky=2, smoothing=0.5)\n\nUses Dierckx.Spline2D for interpolation.\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"One can define your own interpolation by subtyping:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.Interpolator","category":"page"},{"location":"general/#TopoPlots.Interpolator","page":"General TopoPlots","title":"TopoPlots.Interpolator","text":"Interface for all types <: Interpolator:\n\ninterpolator = Interpolator(; kw_specific_to_interpolator)\ninterpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The different interpolation schemes look quite different:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"using LinearAlgebra, Statistics, TopoPlots, CairoMakie\n\ndata = Array{Float32}(undef, 64, 400, 3)\nread!(TopoPlots.assetpath(\"example-data.bin\"), data)\n\npositions = Vector{Point2f}(undef, 64)\nread!(TopoPlots.assetpath(\"layout64.bin\"), positions)\n\nf = Figure(resolution=(1000, 1000))\ninterpolators = [DelaunayMesh(), ClaughTochter(), SplineInterpolator()]\ndata_slice = data[:, 360, 1]\n\nfor (i, interpolation) in enumerate(interpolators)\n    j = i == 3 ? (:) : i\n    TopoPlots.topoplot(\n        f[((i - 1) ÷ 2) + 1, j], data_slice, positions;\n        contours=true,\n        interpolation=interpolation,\n        labels = string.(1:length(positions)), colorrange=(-1, 1),\n        axis=(type=Axis, title=\"$(typeof(interpolation))()\",aspect=DataAspect(),))\nend\nf","category":"page"},{"location":"general/#Interactive-exploration","page":"General TopoPlots","title":"Interactive exploration","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"DelaunayMesh is best suited for interactive data exploration, which can be done quite easily with Makie's native UI and observable framework:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"f = Figure(resolution=(1000, 1000))\ns = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)\ndata_obs = map(s.value) do idx\n    data[:, idx, 1]\nend\nTopoPlots.topoplot(\n    f[2, 1],\n    data_obs, positions,\n    interpolation=DelaunayMesh(),\n    labels = string.(1:length(positions)),\n    colorrange=(-1, 1),\n    colormap=:viridis,\n    axis=(title=\"delaunay mesh\",aspect=DataAspect(),))\nf","category":"page"},{"location":"general/#Different-geometry","page":"General TopoPlots","title":"Different geometry","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The bounding geometry pads the input data with more points in the form of the geometry. So e.g. for maps, one can use Rect as the bounding geometry:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.topoplot(\n    rand(10), rand(Point2f, 10),\n    axis=(; aspect=DataAspect()),\n    colorrange=(-1, 1),\n    bounding_geometry = Rect,\n    label_scatter=(; strokewidth=2),\n    contours=(linewidth=2, color=:white))","category":"page"},{"location":"eeg/#EEG-Topoplots","page":"EEG","title":"EEG Topoplots","text":"","category":"section"},{"location":"eeg/","page":"EEG","title":"EEG","text":"The eeg_topoplot recipe adds a bit of convience for plotting Topoplots from eeg data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as topoplot.","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"TopoPlots.eeg_topoplot","category":"page"},{"location":"eeg/#TopoPlots.eeg_topoplot","page":"EEG","title":"TopoPlots.eeg_topoplot","text":"eeg_topoplot(data::Vector{<: Real}, labels::Vector{<: AbstractString})\n\nAttributes:\n\npositions::Vector{<: Point} = Makie.automatic: Can be calculated from label (channel) names. Currently, only 10/20 montage is supported.\nhead = (color=:black, linewidth=3): draw the outline of the head. Set to nothing to not draw the head outline, otherwise set to a namedtuple that get passed down to the line! call that draws the shape.\n\nSome attributes from topoplot are set to different defaults:\n\nlabel_scatter = true\ncontours = true\n\nOtherwise the recipe just uses the topoplot defaults and passes through the attributes.\n\n\n\n\n\n","category":"function"},{"location":"eeg/","page":"EEG","title":"EEG","text":"So for the standard 10/20 montage, one can drop the positions attribute:","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"using TopoPlots, CairoMakie\n\nlabels = TopoPlots.CHANNELS_10_20\nTopoPlots.eeg_topoplot(rand(19), labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"If the channels aren't 10/20, one can still plot them, but then the positions need to get passed as well:","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"\ndata = Array{Float32}(undef, 64, 400, 3)\nread!(TopoPlots.assetpath(\"example-data.bin\"), data)\npositions = Vector{Point2f}(undef, 64)\nread!(TopoPlots.assetpath(\"layout64.bin\"), positions)\nlabels = [\"s$i\" for i in 1:size(data, 1)]\nTopoPlots.eeg_topoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = TopoPlots","category":"page"},{"location":"#TopoPlots","page":"Home","title":"TopoPlots","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TopoPlots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A package for creating topoplots from data that got measured on arbitrary positioned sensors:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TopoPlots, CairoMakie\ntopoplot(rand(10), rand(Point2f, 10); contours=(color=:white, linewidth=2), label_scatter=true)","category":"page"},{"location":"","page":"Home","title":"Home","text":"Find more documentation for topoplot in Recipe for General TopoPlots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"It also contains some more convenience for eeg data, which is explained in EEG Topoplots.","category":"page"}]
}
