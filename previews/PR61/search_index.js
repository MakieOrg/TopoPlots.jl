var documenterSearchIndex = {"docs":
[{"location":"functions/#Function-Reference","page":"Function reference","title":"Function Reference","text":"","category":"section"},{"location":"functions/","page":"Function reference","title":"Function reference","text":"TopoPlots.enclosing_geometry\nTopoPlots.labels2positions","category":"page"},{"location":"functions/#TopoPlots.enclosing_geometry","page":"Function reference","title":"TopoPlots.enclosing_geometry","text":"enclosing_geometry(G::Type{<: Geometry}, positions, enlarge=1.0)\n\nReturns the Geometry of Type G, that best fits all positions. The Geometry can be enlarged by 1.x, so e.g. enclosing_geometry(Circle, positions, 0.1) will return a Circle that encloses all positions with a padding of 10%.\n\n\n\n\n\n","category":"function"},{"location":"functions/#TopoPlots.labels2positions","page":"Function reference","title":"TopoPlots.labels2positions","text":"labels2positions(labels)\n\nCurrently supports 10/20 and 10/05 layout, by looking it up in TopoPlots.CHANNEL_TO_POSITION_10_05.\n\n\n\n\n\n","category":"function"},{"location":"general/#Recipe-for-General-TopoPlots","page":"General TopoPlots","title":"Recipe for General TopoPlots","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"At the core of TopoPlots.jl is the topoplot recipe, which takes an array of measurements and an array of positions, which then creates a heatmap like plot which interpolates between the measurements from the positions.","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.topoplot","category":"page"},{"location":"general/#TopoPlots.topoplot","page":"General TopoPlots","title":"TopoPlots.topoplot","text":"topoplot(data::Vector{<:Real}, positions::Vector{<: Point2})\n\nCreates an irregular interpolation for each data[i] point at positions[i].\n\nAttributes\n\ncolormap = Reverse(:RdBu)\ncolorrange = automatic\nlabels::Vector{<:String} = nothing: names for each data point\ninterpolation::Interpolator = CloughTocher(): Applicable interpolators are TopoPlots.CloughTocher, TopoPlots.DelaunayMesh, TopoPlots.NaturalNeighboursMethod, TopoPlots.NullInterpolator, TopoPlots.ScatteredInterpolationMethod, TopoPlots.SplineInterpolator\nextrapolation = GeomExtrapolation(): Extrapolation method for adding additional points to get less border artifacts\nbounding_geometry = Circle: A geometry that defines what to mask and the x/y extend of the interpolation. E.g. Rect(0, 0, 100, 200), will create a heatmap(0..100, 0..200, ...). By default, a circle enclosing the positions points will be used.\nenlarge = 1.2, enlarges the area that is being drawn. E.g., ifbounding_geometryisCircle`, a circle will be fitted to the points and the interpolation area that gets drawn will be 1.2x that bounding circle.\ninterp_resolution = (512, 512): resolution of the interpolation\nlabel_text = false:\ntrue: add text plot for each position from labels\nNamedTuple: Attributes get passed to the Makie.text! call.\nlabel_scatter = false:\ntrue: add point for each position with default attributes\nNamedTuple: Attributes get passed to the Makie.scatter! call.\nmarkersize = 5: size of the points defined by positions, shortcut for label_scatter=(markersize=5,)\nplotfnc! = heatmap!: function to use for plotting the interpolation\nplotfnc_kwargs_names = [:colorrange, :colormap, :interpolate]: different plotfnc support different kwargs, this array contains the keys to filter the full list which is [:colorrange, :colormap, :interpolate]\ncontours = false:\ntrue: add scatter point for each position\nNamedTuple: Attributes get passed to the Makie.contour! call.\n\nExample\n\nusing TopoPlots, CairoMakie\ntopoplot(rand(10), rand(Point2f, 10); contours=(color=:red, linewidth=2))\n\n\n\n\n\n","category":"function"},{"location":"general/#Interpolation","page":"General TopoPlots","title":"Interpolation","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots provides access to interpolators from several different Julia packages through its TopoPlots.Interpolator interface.","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"They can be accessed via plotting, or directly by calling the instantiated interpolator object as is shown below, namely with the arguments (::Interpolator)(xrange::LinRange, yrange::LinRange, positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number}).  This is similar to using things like Matlab's regrid function.  You can find more details in the Interpolation section.","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The recipe supports different interpolation methods, namely:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.DelaunayMesh\nTopoPlots.CloughTocher\nTopoPlots.SplineInterpolator\nTopoPlots.ScatteredInterpolationMethod\nTopoPlots.NaturalNeighboursMethod\nTopoPlots.NullInterpolator","category":"page"},{"location":"general/#TopoPlots.DelaunayMesh","page":"General TopoPlots","title":"TopoPlots.DelaunayMesh","text":"DelaunayMesh()\n\nCreates a delaunay triangulation of the points and linearly interpolates between the vertices of the triangle. Really fast interpolation that happens on the GPU (for GLMakie), so optimal for exploring larger timeseries.\n\nwarning: Warning\nDelaunayMesh won't allow you to add a contour plot to the topoplot.\n\ndanger: Danger\nDelaunayMesh will not behave accurately if rendered via CairoMakie, because Cairo (and SVG in general) does not support color maps on meshes.  The color within each triangle will be based only on the values  at the vertices, which causes inaccurate visuals.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.CloughTocher","page":"General TopoPlots","title":"TopoPlots.CloughTocher","text":"CloughTocher(fill_value=NaN, tol=1e-6, maxiter=400, rescale=false)\n\nPiecewise cubic, C1 smooth, curvature-minimizing interpolant in 2D. Find more detailed docs in CloughTocher2DInterpolation.jl.\n\nThis is the default interpolator in MNE-Python.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.SplineInterpolator","page":"General TopoPlots","title":"TopoPlots.SplineInterpolator","text":"SplineInterpolator(;kx=2, ky=2, smoothing=0.5)\n\nUses Dierckx.Spline2D for interpolation.\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.ScatteredInterpolationMethod","page":"General TopoPlots","title":"TopoPlots.ScatteredInterpolationMethod","text":"ScatteredInterpolationMethod(InterpolationMethod)\n\nContainer to specify a InterpolationMethod from ScatteredInterpolation.jl. E.g. ScatteredInterpolationMethod(Shepard(P=4))\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.NaturalNeighboursMethod","page":"General TopoPlots","title":"TopoPlots.NaturalNeighboursMethod","text":"NaturalNeighboursMethod(; method=Sibson(1), kwargs...)\n\nInterpolator that uses the NaturalNeighbours.jl package to interpolate the data.  This uses Delaunay triangulations and  the corresponding Voronoi diagram to interpolate the data, and offers a variety of methods like Sibson(::Int), Nearest(), and Triangle().\n\nThe advantage of Voronoi-diagram based methods is that they are more robust to  irregularly distributed datasets and some discontinuities, which may throw off  some polynomial based methods as well as independant distance weighting (kriging).  See this Discourse post for more information on why NaturalNeighbours are cool! \n\nTo access the methods easily, you should run using NearestNeighbours.\n\nSee the NaturalNeighbours documentation for more details.\n\nThis method is fully configurable and will forward all arguments to the relevant NaturalNeighbours.jl functions. To understand what the methods do, see the documentation for NaturalNeighbours.jl.\n\nKeyword arguments\n\nThe main keyword argument to look at here is method, which is the method to use for the interpolation.  The other keyword arguments are simply forwarded  to NaturalNeighbours.jl's interpolator.\n\nmethod: The method to use for the interpolation.  Defaults to `Sibson(1). Default: NaturalNeighbours.Sibson{1}()\nparallel: Whether to use multithreading when interpolating.  Defaults to true. Default: true\nproject: Whether to project the data onto the Delaunay triangulation.  Defaults to true. Default: true\nderivative_method: The method to use for the differentiation.  Defaults to Direct().  May be Direct() or Iterative(). Default: NaturalNeighbours.Direct()\nuse_cubic_terms: Whether to use cubic terms for estimating the second order derivatives. Only relevant for derivative_method == Direct(). Default: true\nalpha: The weighting parameter used for estimating the second order derivatives. Only relevant for derivative_method == Iterative(). Default: 0.1\n\n\n\n\n\n","category":"type"},{"location":"general/#TopoPlots.NullInterpolator","page":"General TopoPlots","title":"TopoPlots.NullInterpolator","text":"NullInterpolator()\n\nInterpolator that returns \"0\", which is useful to display only the electrode locations + labels\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"You can define your own interpolation by subtyping:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.Interpolator","category":"page"},{"location":"general/#TopoPlots.Interpolator","page":"General TopoPlots","title":"TopoPlots.Interpolator","text":"Interface for all types <: Interpolator:\n\ninterpolator = Interpolator(; kw_specific_to_interpolator)\ninterpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"and making your interpolator SomeInterpolator callable with the signature","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"(::SomeInterpolator)(xrange::LinRange, yrange::LinRange, positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number}; mask=nothing)","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"See also Interpolator Comparison.","category":"page"},{"location":"general/#Extrapolation","page":"General TopoPlots","title":"Extrapolation","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"There are currently just two extrapolations: None (NullExtrapolation()) and a geometry based one:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.GeomExtrapolation","category":"page"},{"location":"general/#TopoPlots.GeomExtrapolation","page":"General TopoPlots","title":"TopoPlots.GeomExtrapolation","text":"GeomExtrapolation(\n    method = Shepard(), # extrapolation method\n    geometry = Rect, # the geometry to fit around the points\n    enlarge = 3.0 # the amount to grow the bounding geometry for adding the extra points\n)\n\nTakes positions and data, and returns points and additional datapoints on an enlarged bounding geometry:\n\nextra = GeomExtrapolation()\nextra_positions, extra_data, bounding_geometry, bounding_geometry_enlarged = extra(positions, data)\n\n\n\n\n\n","category":"type"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The extrapolations in action:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"using CairoMakie, TopoPlots\n\ndata, positions = TopoPlots.example_data()\ntitles = [\"No Extrapolation\", \"Rect\", \"Circle\"]\ndata_slice = data[:, 340, 1]\nf = Figure(resolution=(900, 300))\nfor (i, extra) in enumerate([NullExtrapolation(), GeomExtrapolation(enlarge=3.0), GeomExtrapolation(enlarge=3.0, geometry=Circle)])\n    pos_extra, data_extra, rect_extended, rect = extra(positions, data_slice)\n    geom = extra isa NullExtrapolation ? Rect : extra.geometry\n    # Note, that enlarge doesn't match (the default), the additional points won't be seen and masked by `bounding_geometry` and `enlarge`.\n    enlarge = extra isa NullExtrapolation ? 1.0 : extra.enlarge\n    ax, p = topoplot(f[1, i], data_slice, positions; extrapolation=extra, bounding_geometry=geom, enlarge=enlarge, axis=(aspect=DataAspect(), title=titles[i]))\n    scatter!(ax, pos_extra, color=data_extra, markersize=10, strokewidth=0.5, strokecolor=:white, colormap = p.colormap, colorrange = p.colorrange)\n    lines!(ax, rect_extended, color=:black, linewidth=4)\n    lines!(ax, rect, color=:red, linewidth=1)\nend\nresize_to_layout!(f)\nf","category":"page"},{"location":"general/#Interactive-exploration","page":"General TopoPlots","title":"Interactive exploration","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"DelaunayMesh is best suited for interactive data exploration, which can be done quite easily with Makie's native UI and observable framework:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"f = Figure(resolution=(1000, 1250))\ns = Slider(f[:, 1], range=1:size(data, 2), startvalue=351)\ndata_obs = map(s.value) do idx\n    data[:, idx, 1]\nend\nTopoPlots.topoplot(\n    f[2, 1],\n    data_obs, positions,\n    interpolation=DelaunayMesh(),\n    labels = string.(1:length(positions)),\n    colorrange=(-1, 1),\n    colormap=:viridis,\n    axis=(title=\"delaunay mesh\",aspect=DataAspect(),))\nf","category":"page"},{"location":"general/#Different-geometry","page":"General TopoPlots","title":"Different geometry","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"The bounding geometry pads the input data with more points in the form of the geometry. So e.g. for maps, one can use Rect as the bounding geometry:","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"TopoPlots.topoplot(\n    rand(10), rand(Point2f, 10),\n    axis=(; aspect=DataAspect()),\n    colorrange=(-1, 1),\n    bounding_geometry = Rect,\n    label_scatter=(; strokewidth=2),\n    contours=(linewidth=2, color=:white))","category":"page"},{"location":"general/#Different-plotfunctions","page":"General TopoPlots","title":"Different plotfunctions","text":"","category":"section"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"It is possible to exchange the plotting function, from heatmap! to contourf! or surface!. Due to different keyword arguments, one needs to filter which keywords are passed to the plotting function manually.","category":"page"},{"location":"general/","page":"General TopoPlots","title":"General TopoPlots","text":"f = Figure()\n\nTopoPlots.topoplot(f[1,1],\n    rand(10), rand(Point2f, 10),\n    axis=(; aspect=DataAspect()),\n    plotfnc! = contourf!, plotfnc_kwargs_names=[:colormap])\n\nTopoPlots.topoplot(f[1,2],\n    rand(10), rand(Point2f, 10),\n    axis=(; aspect=DataAspect()),\n    plotfnc! = surface!) # surface can take all default kwargs similar to heatmap!\n\nf","category":"page"},{"location":"eeg/#EEG-Topoplots","page":"EEG","title":"EEG Topoplots","text":"","category":"section"},{"location":"eeg/","page":"EEG","title":"EEG","text":"The eeg_topoplot recipe adds a bit of convenience for plotting Topoplots from EEG data, like drawing a head shape and automatically looking up default positions for known sensors. Otherwise, it supports the same attributes as topoplot.","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"TopoPlots.eeg_topoplot","category":"page"},{"location":"eeg/#TopoPlots.eeg_topoplot","page":"EEG","title":"TopoPlots.eeg_topoplot","text":"eeg_topoplot(data::Vector{<: Real}, labels::Vector{<: AbstractString})\n\nAttributes:\n\npositions::Vector{<: Point} = Makie.automatic: Can be calculated from label (channel) names. Currently, only 10/20 montage has default coordinates provided.\nlabels::AbstractVector{<:AbstractString} = Makie.automatic: Add custom labels, when label_text is set to true. If positions is not specified, labels are used to look up the 10/20 coordinates.\nhead = (color=:black, linewidth=3): draw the outline of the head. Set to nothing to not draw the head outline, otherwise set to a namedtuple that get passed down to the line! call that draws the shape.\n\nSome attributes from topoplot are set to different defaults:\n\nlabel_scatter = true\ncontours = true\nenlarge = 1`\n\nOtherwise the recipe just uses the topoplot defaults and passes through the attributes.\n\nnote: Note\nThe 10-05 channel locations are \"perfect\" spherical locations based on https://github.com/sappelhoff/eegpositions/ - the mne-default 10-20 locations are _not, they were warped to a fsaverage head. Which makes the locations provided here good for visualizations, but not good for source localisation.\n\nnote: Note\nYou MUST set label_text=true for labels to display.\n\n\n\n\n\n","category":"function"},{"location":"eeg/","page":"EEG","title":"EEG","text":"For the standard 10/20 (or 10/05) montage, one can drop the positions attribute:","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"using TopoPlots, CairoMakie\n\nlabels = TopoPlots.CHANNELS_10_05 # TopoPlots.CHANNELS_10_20 contains the 10/20 subset\n\nf,ax,h = TopoPlots.eeg_topoplot(rand(348); labels=labels, axis=(aspect=DataAspect(),), label_text=true, label_scatter=(markersize=2, strokewidth=2,),colorrange=[-5,5])\n","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"If the channels aren't 10/05, one can still plot them, but then the positions need to be passed as well:","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"data, positions = TopoPlots.example_data()\nlabels = [\"s$i\" for i in 1:size(data, 1)]\nTopoPlots.eeg_topoplot(data[:, 340, 1]; labels, label_text = true, positions=positions, axis=(aspect=DataAspect(),))","category":"page"},{"location":"eeg/#Subset-of-channels","page":"EEG","title":"Subset of channels","text":"","category":"section"},{"location":"eeg/","page":"EEG","title":"EEG","text":"If you only ask to plot a subset of channels, we highly recommend to define your bounding geometry yourself. We follow MNE functionality and normalize the positions prior to interpolation / plotting. If you only use a subset of channels, the positions will be relative to each other, not at absolute coordinates.","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"f = Figure()\nax1 = f[1,1] = Axis(f;aspect=DataAspect())\nax2 = f[1,2] = Axis(f;aspect=DataAspect())\nkwlist = (;label_text=true,label_scatter=(markersize=10, strokewidth=2,color=:white))\nTopoPlots.eeg_topoplot!(ax1,[1,0.5,0]; labels=[\"Cz\",\"Fz\",\"Fp1\"],kwlist...)\nTopoPlots.eeg_topoplot!(ax2,[1,0.5,05]; labels=[\"Cz\",\"Fz\",\"Fp1\"], bounding_geometry=Circle(Point2f(0.5,0.5), 0.5),kwlist...)\n\nf","category":"page"},{"location":"eeg/","page":"EEG","title":"EEG","text":"As visible in the left plot, the positions are normalized to the bounding geometry. The right plot shows the same data, but with Cz correctly centered.","category":"page"},{"location":"eeg/#Example-data","page":"EEG","title":"Example data","text":"","category":"section"},{"location":"eeg/","page":"EEG","title":"EEG","text":"TopoPlots.example_data","category":"page"},{"location":"eeg/#TopoPlots.example_data","page":"EEG","title":"TopoPlots.example_data","text":"example_data()\n\nLoad EEG example data.\n\nReturns a two-tuple:\n\ndata: a (64, 400, 3) Float32 array of channel x timepoint x stat array. Timepoints correponds to samples at 500Hz from -0.3s to 0.5s relative to stimulus onset. Stats are mean over subjects, standard errors over subjects, and associated p-value from a t-test. For demonstration purposes, the first stat dimension is generally the most applicable.\npositions: a length-64 Point2f vector of positions for each channel in data.\n\nData source\n\nEhinger, B. V., König, P., & Ossandón, J. P. (2015). Predictions of Visual Content across Eye Movements and Their Modulation by Inferred Information. The Journal of Neuroscience, 35(19), 7403–7413. https://doi.org/10.1523/JNEUROSCI.5114-14.2015\n\n\n\n\n\n","category":"function"},{"location":"interpolator_reference/#Interpolator-Comparison","page":"Interpolator reference images","title":"Interpolator Comparison","text":"","category":"section"},{"location":"interpolator_reference/","page":"Interpolator reference images","title":"Interpolator reference images","text":"This file contains reference figures showing the output of each interpolator available in TopoPlots, as well as timings for them.","category":"page"},{"location":"interpolator_reference/","page":"Interpolator reference images","title":"Interpolator reference images","text":"It is a more comprehensive version of the plot in Interpolation.","category":"page"},{"location":"interpolator_reference/","page":"Interpolator reference images","title":"Interpolator reference images","text":"\nusing TopoPlots, CairoMakie, ScatteredInterpolation, NaturalNeighbours\n\ndata, positions = TopoPlots.example_data()\n\nf = Figure(size=(1000, 1500))\n\ninterpolators = [\n    SplineInterpolator() NullInterpolator() DelaunayMesh();\n    CloughTocher() ScatteredInterpolationMethod(ThinPlate()) ScatteredInterpolationMethod(Shepard(3));\n    ScatteredInterpolationMethod(Multiquadratic()) ScatteredInterpolationMethod(InverseMultiquadratic()) ScatteredInterpolationMethod(Gaussian());\n    NaturalNeighboursMethod(Hiyoshi(2)) NaturalNeighboursMethod(Sibson()) NaturalNeighboursMethod(Laplace());\n    NaturalNeighboursMethod(Farin()) NaturalNeighboursMethod(Sibson(1)) NaturalNeighboursMethod(Nearest());\n    ]\n\ndata_slice = data[:, 360, 1]\n\nfor idx in CartesianIndices(interpolators)\n    interpolation = interpolators[idx]\n    @info \"\" interpolation\n\n    # precompile to get accurate measurements\n    TopoPlots.topoplot(data_slice, positions;\n                       contours=true, interpolation,\n                       labels=string.(1:length(positions)), colorrange=(-1, 1),\n                       label_scatter=(markersize=10,),\n                       axis=(type=Axis, title=\"...\", aspect=DataAspect(),))\n\n    # measure time, to give an idea of what speed to expect from the different interpolators\n    t = @elapsed ax, pl = TopoPlots.topoplot(\n        f[Tuple(idx)...], data_slice, positions;\n        contours=true,\n        interpolation=interpolation,\n        labels = string.(1:length(positions)), colorrange=(-1, 1),\n        label_scatter=(markersize=10,),\n        axis=(type=Axis, title=\"$(typeof(interpolation))()\",aspect=DataAspect(),))\n\n   ax.title = (\"$(typeof(interpolation))() - $(round(t, digits=2))s\")\n   if interpolation isa Union{NaturalNeighboursMethod, ScatteredInterpolationMethod}\n       ax.title = \"$(typeof(interpolation))() - $(round(t, digits=2))s\"\n       ax.subtitle = string(typeof(interpolation.method))\n   end\nend\nf","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = TopoPlots","category":"page"},{"location":"#TopoPlots","page":"Home","title":"TopoPlots","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TopoPlots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"A package for creating topoplots from data that were measured on arbitrarily positioned sensors:","category":"page"},{"location":"","page":"Home","title":"Home","text":"using TopoPlots, CairoMakie\nf = Figure(;resolution=(800,280))\ntopoplot(f[1,1],rand(20), rand(Point2f, 20))\ntopoplot(f[1,2],rand(20), rand(Point2f, 20); contours=(color=:white, linewidth=2),\n         label_scatter=true, bounding_geometry=Rect(0,0,1,1), colormap=:viridis)\neeg_topoplot(f[1,3],rand(20),1:20;positions=rand(Point2f, 20), colormap=:Oranges)\nf","category":"page"},{"location":"","page":"Home","title":"Home","text":"Find more documentation for topoplot in Recipe for General TopoPlots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"It also contains some more convenience methods for EEG data, which is explained in EEG Topoplots.","category":"page"},{"location":"","page":"Home","title":"Home","text":"You can also use TopoPlots' interpolators as a simple interface to regrid irregular data.  See Interpolation for more details.","category":"page"}]
}