var documenterSearchIndex = {"docs":
[{"location":"functions/#Function-Reference","page":"Function reference","title":"Function Reference","text":"","category":"section"},{"location":"functions/","page":"Function reference","title":"Function reference","text":"TopoPlots.enclosing_geometry\nTopoPlots.labels2positions","category":"page"},{"location":"functions/#TopoPlots.enclosing_geometry","page":"Function reference","title":"TopoPlots.enclosing_geometry","text":"enclosing_geometry(G::Type{<: Geometry}, positions, enlarge=1.0)\n\nReturns the Geometry of Type G, that best fits all positions. The Geometry can be enlarged by 1.x, so e.g. enclosing_geometry(Circle, positions, 0.1) will return a Circle that encloses all positions with a padding of 10%.\n\n\n\n\n\n","category":"function"},{"location":"functions/#TopoPlots.labels2positions","page":"Function reference","title":"TopoPlots.labels2positions","text":"labels2positions(labels)\n\nCurrently only supports 10/20 layout, by looking it up in TopoPlots.CHANNEL_TO_POSITION_10_20.\n\n\n\n\n\n","category":"function"},{"location":"general/#Recipe-for-General-TopoPlots","page":"General TopoPlots","title":"Recipe for General TopoPlots","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"At the core of TopoPlots.jl is the topoplot recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.topoplot","category":"page"},{"location":"general/#TopoPlots.topoplot","page":"General TopoPlots","title":"TopoPlots.topoplot","text":"topoplot(data::Vector{<:Real}, positions::Vector{<: Point2})\n\nCreates an irregular interpolation for each data[i] point at positions[i].\n\nAttributes\n\ncolormap = Reverse(:RdBu)\ncolorrange = automatic\nlabels::Vector{<:String} = nothing: names for each data point\ninterpolation::Interpolator = CloughTocher(): Applicable interpolators are TopoPlots.CloughTocher, TopoPlots.DelaunayMesh, TopoPlots.NullInterpolator, TopoPlots.ScatteredInterpolationMethod, TopoPlots.SplineInterpolator\nextrapolation = GeomExtrapolation(): Extrapolation method for adding additional points to get less border artifacts\nbounding_geometry = Circle: A geometry that defines what to mask and the x/y extend of the interpolation. E.g. Rect(0, 0, 100, 200), will create a heatmap(0..100, 0..200, ...). By default, a circle enclosing the positions points will be used.\nenlarge = 1.2, enlarges the area that is being drawn. E.g., ifbounding_geometryisCircle`, a circle will be fitted to the points and the interpolation area that gets drawn will be 1.2x that bounding circle.\ninterp_resolution = (512, 512): resolution of the interpolation\nlabel_text = false:\ntrue: add text plot for each position from labels\nNamedTuple: Attributes get passed to the Makie.text! call.\nlabel_scatter = false:\ntrue: add point for each position with default attributes\nNamedTuple: Attributes get passed to the Makie.scatter! call.\nmarkersize = 5: size of the points defined by positions, shortcut for label_scatter=(markersize=5,)\ncontours = false:\ntrue: add scatter point for each position\nNamedTuple: Attributes get passed to the Makie.contour! call.\n\nExample\n\nusing TopoPlots, CairoMakie\ntopoplot(rand(10), rand(Point2f, 10); contours=(color=:red, linewidth=2))\n\n\n\n\n\n","category":"function"},{"location":"general/#Interpolation","page":"General TopoPlots","title":"Interpolation","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The recipe supports different interpolation methods, namely:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.DelaunayMesh\nTopoPlots.CloughTocher\nTopoPlots.SplineInterpolator\nTopoPlots.ScatteredInterpolationMethod\nTopoPlots.NullInterpolator","category":"page"},{"location":"general/#TopoPlots.DelaunayMesh","page":"General TopoPlots","title":"TopoPlots.DelaunayMesh","text":"DelaunayMesh()\n\nCreates a delaunay triangulation of the points and linearly interpolates between the vertices of the triangle. Really fast interpolation that happens on the GPU (for GLMakie), so optimal for exploring larger timeseries.\n\nwarning: Warning\nDelaunayMesh won't allow you to add a contour plot to the topoplot.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.CloughTocher","page":"General TopoPlots","title":"TopoPlots.CloughTocher","text":"CloughTocher(fill_value=NaN, tol=1e-6, maxiter=400, rescale=false)\n\nPiecewise cubic, C1 smooth, curvature-minimizing interpolant in 2D. Find more detailed docs in CloughTocher2DInterpolator.jl.\n\nThis is the default interpolator in MNE-Python\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.SplineInterpolator","page":"General TopoPlots","title":"TopoPlots.SplineInterpolator","text":"SplineInterpolator(;kx=2, ky=2, smoothing=0.5)\n\nUses Dierckx.Spline2D for interpolation.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.ScatteredInterpolationMethod","page":"General TopoPlots","title":"TopoPlots.ScatteredInterpolationMethod","text":"ScatteredInterpolationMethod(InterpolationMethod)\n\nContainer to specify a `InterpolationMethod` from ScatteredInterpolation.\nE.g. ScatteredInterpolationMethod(Shepard(P=4))\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.NullInterpolator","page":"General TopoPlots","title":"TopoPlots.NullInterpolator","text":"NullInterpolator()\n\nInterpolator that returns \"0\", which is useful to display only the electrode locations + labels\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"One can define your own interpolation by subtyping:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.Interpolator","category":"page"},{"location":"general/#TopoPlots.Interpolator","page":"General TopoPlots","title":"TopoPlots.Interpolator","text":"Interface for all types <: Interpolator:\n\ninterpolator = Interpolator(; kw_specific_to_interpolator)\ninterpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The different interpolation schemes look quite different:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"using TopoPlots, CairoMakie, ScatteredInterpolation\n\ndata, positions = TopoPlots.example_data()\n\nf = Figure(resolution=(1000, 1000))\n\ninterpolators = [\n    DelaunayMesh() CloughTocher();\n    SplineInterpolator() NullInterpolator();\n    ScatteredInterpolationMethod(ThinPlate()) ScatteredInterpolationMethod(Shepard(3))]\n\ndata_slice = data[:, 360, 1]\n\nfor idx in CartesianIndices(interpolators)\n    interpolation = interpolators[idx]\n\n    # precompile to get accurate measurements\n    TopoPlots.topoplot(\n        data_slice, positions;\n        contours=true, interpolation=interpolation,\n        labels = string.(1:length(positions)), colorrange=(-1, 1),\n        label_scatter=(markersize=10,),\n        axis=(type=Axis, title=\"...\", aspect=DataAspect(),))\n\n    # measure time, to give an idea of what speed to expect from the different interpolators\n    t = @elapsed ax, pl = TopoPlots.topoplot(\n        f[Tuple(idx)...], data_slice, positions;\n        contours=true,\n        interpolation=interpolation,\n        labels = string.(1:length(positions)), colorrange=(-1, 1),\n        label_scatter=(markersize=10,),\n        axis=(type=Axis, title=\"$(typeof(interpolation))()\",aspect=DataAspect(),))\n\n   ax.title = (\"$(typeof(interpolation))() - $(round(t, digits=2))s\")\nend\nf","category":"page"},{"location":"general/#Extrapolation","page":"General TopoPlots","title":"Extrapolation","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"There are currently just two extrapolations: None (NullExtrapolation()) and a geometry based one:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.GeomExtrapolation","category":"page"},{"location":"general/#TopoPlots.GeomExtrapolation","page":"General TopoPlots","title":"TopoPlots.GeomExtrapolation","text":"GeomExtrapolation(\n    method = Shepard(), # extrapolation method\n    geometry = Rect, # the geometry to fit around the points\n    enlarge = 3.0 # the amount to grow the bounding geometry for adding the extra points\n)\n\nTakes positions and data, and returns points and additional datapoints on an enlarged bounding geometry:\n\nextra = GeomExtrapolation()\nextra_positions, extra_data, bounding_geometry, bounding_geometry_enlarged = extra(positions, data)\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The extrapolations in action:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"data, positions = TopoPlots.example_data()\ntitles = [\"No Extrapolation\", \"Rect\", \"Circle\"]\ndata_slice = data[:, 340, 1]\nf = Figure(resolution=(900, 300))\nfor (i, extra) in enumerate([NullExtrapolation(), GeomExtrapolation(enlarge=3.0), GeomExtrapolation(enlarge=3.0, geometry=Circle)])\n    pos_extra, data_extra, rect_extended, rect = extra(positions, data_slice)\n    geom = extra isa NullExtrapolation ? Rect : extra.geometry\n    # Note, that enlarge doesn't match (the default), the additional points won't be seen and masked by `bounding_geometry` and `enlarge`.\n    enlarge = extra isa NullExtrapolation ? 1.0 : extra.enlarge\n    ax, p = topoplot(f[1, i], data_slice, positions; extrapolation=extra, bounding_geometry=geom, enlarge=enlarge, axis=(aspect=DataAspect(), title=titles[i]))\n    scatter!(ax, pos_extra, color=data_extra, markersize=10, strokewidth=0.5, strokecolor=:white, colormap = p.colormap, colorrange = p.colorrange)\n    lines!(ax, rect_extended, color=:black, linewidth=4)\n    lines!(ax, rect, color=:red, linewidth=1)\nend\nresize_to_layout!(f)\nf","category":"page"},{"location":"general/#Interactive-exploration","page":"General TopoPlots","title":"Interactive exploration","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"DelaunayMesh is best suited for interactive data exploration, which can be done quite easily with Makie's native UI and observable framework:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"f = Figure(resolution=(1000, 1000))\ns = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)\ndata_obs = map(s.value) do idx\n    data[:, idx, 1]\nend\nTopoPlots.topoplot(\n    f[2, 1],\n    data_obs, positions,\n    interpolation=DelaunayMesh(),\n    labels = string.(1:length(positions)),\n    colorrange=(-1, 1),\n    colormap=:viridis,\n    axis=(title=\"delaunay mesh\",aspect=DataAspect(),))\nf","category":"page"},{"location":"general/#Different-geometry","page":"General TopoPlots","title":"Different geometry","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The bounding geometry pads the input data with more points in the form of the geometry. So e.g. for maps, one can use Rect as the bounding geometry:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.topoplot(\n    rand(10), rand(Point2f, 10),\n    axis=(; aspect=DataAspect()),\n    colorrange=(-1, 1),\n    bounding_geometry = Rect,\n    label_scatter=(; strokewidth=2),\n    contours=(linewidth=2, color=:white))","category":"page"},{"location":"eeg/#EEG-Topoplots","page":"EEG","title":"EEG Topoplots","text":"","category":"section"},{"location":"eeg/","page":"EEG","title":"EEG","text":"The eeg_topoplot recipe adds a bit of convenience for plotting Topoplots from EEG data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as topoplot.","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"TopoPlots.eeg_topoplot","category":"page"},{"location":"eeg/#TopoPlots.eeg_topoplot","page":"EEG","title":"TopoPlots.eeg_topoplot","text":"eeg_topoplot(data::Vector{<: Real}, labels::Vector{<: AbstractString})\n\nAttributes:\n\npositions::Vector{<: Point} = Makie.automatic: Can be calculated from label (channel) names. Currently, only 10/20 montage has default coordinates provided.\nhead = (color=:black, linewidth=3): draw the outline of the head. Set to nothing to not draw the head outline, otherwise set to a namedtuple that get passed down to the line! call that draws the shape.\n\nSome attributes from topoplot are set to different defaults:\n\nlabel_scatter = true\ncontours = true\n\nOtherwise the recipe just uses the topoplot defaults and passes through the attributes.\n\n\n\n\n\n","category":"function"},{"location":"eeg/","page":"EEG","title":"EEG","text":"So for the standard 10/20 montage, one can drop the positions attribute:","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"using TopoPlots, CairoMakie\n\nlabels = TopoPlots.CHANNELS_10_20\nTopoPlots.eeg_topoplot(rand(19), labels; axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=10, strokewidth=2,))","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"If the channels aren't 10/20, one can still plot them, but then the positions need to be passed as well:","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"\ndata, positions = TopoPlots.example_data()\nlabels = [\"s$i\" for i in 1:size(data, 1)]\nTopoPlots.eeg_topoplot(data[:, 340, 1], labels; positions=positions, axis=(aspect=DataAspect(),))","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = TopoPlots","category":"page"},{"location":"#TopoPlots","page":"Home","title":"TopoPlots","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TopoPlots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A package for creating topoplots from data that were measured on arbitrarily positioned sensors:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TopoPlots, CairoMakie\nf = Figure(;resolution=(800,280))\ntopoplot(f[1,1],rand(20), rand(Point2f, 20))\ntopoplot(f[1,2],rand(20), rand(Point2f, 20); contours=(color=:white, linewidth=2),\n         label_scatter=true, bounding_geometry=Rect(0,0,1,1), colormap=:viridis)\neeg_topoplot(f[1,3],rand(20),1:20;positions=rand(Point2f, 20),colormap=:Oranges)\n","category":"page"},{"location":"","page":"Home","title":"Home","text":"Find more documentation for topoplot in Recipe for General TopoPlots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"It also contains some more convenience methods for EEG data, which is explained in EEG Topoplots.","category":"page"}]
}