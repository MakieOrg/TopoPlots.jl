@recipe(TopoPlot, data, positions) do scene
    return Attributes(; colormap=Reverse(:RdBu),
                      colorrange=Makie.automatic,
                      sensors=true,
                      interpolation=CloughTocher(),
                      extrapolation=GeomExtrapolation(),
                      bounding_geometry=Circle,
                      enlarge=1.2,
                      markersize=5,
                      pad_value=0.0,
                      interp_resolution=(512, 512),
                      labels=nothing,
                      label_text=false,
                      label_scatter=false,
                      contours=false,
                      (plotfnc!)=(heatmap!),
                      plotfnc_kwargs_names=[:colorrange, :colormap, :interpolate])
end

"""
    topoplot(data::Vector{<:Real}, positions::Vector{<: Point2})

Creates an irregular interpolation for each `data[i]` point at `positions[i]`.

# Attributes

* `colormap = Reverse(:RdBu)`
* `colorrange = automatic`
* `labels::Vector{<:String}` = nothing: names for each data point
* `interpolation::Interpolator = CloughTocher()`: Applicable interpolators are $(join(subtypes(TopoPlots.Interpolator), ", "))
* `extrapolation = GeomExtrapolation()`: Extrapolation method for adding additional points to get less border artifacts
* `bounding_geometry = Circle`: A geometry that defines what to mask and the x/y extend of the interpolation. E.g. `Rect(0, 0, 100, 200)`, will create a `heatmap(0..100, 0..200, ...)`. By default, a circle enclosing the `positions` points will be used.
* `enlarge` = 1.2`, enlarges the area that is being drawn. E.g., if `bounding_geometry` is `Circle`, a circle will be fitted to the points and the interpolation area that gets drawn will be 1.2x that bounding circle.
* `interp_resolution = (512, 512)`: resolution of the interpolation
* `label_scatter = false`:
    * true: add point for each position
    * NamedTuple: Attributes get passed to the Makie.scatter! call.
* `label_text = false`:
    * true: add text plot for each position taken from `labels`
    * NamedTuple: Attributes get passed to the Makie.text! call.
* `markersize = 5`: size of the points defined by positions, shortcut for label_scatter=(markersize=5,)
* `plotfnc! = heatmap!`: function to use for plotting the interpolation
* `contours = false`:
    * true: adds contour-lines with default attributes
    * NamedTuple: Attributes get passed to the Makie.contour! call.

# Example

```julia
using TopoPlots, CairoMakie
topoplot(rand(10), rand(Point2f, 10); contours=(color=:red, linewidth=2))
```
"""
topoplot

function Makie.plot!(p::TopoPlot)
    Obs(x) = Observable(x; ignore_equal_values=true) # we almost never want to trigger updates if value stay the same

    # positions changes with with data together since it gets into convert_arguments

    @debug "Plot attributes" p.attributes
    map!(enclosing_geometry, p.attributes, [:bounding_geometry, :positions, :enlarge],
         :geometry)

    map!(p.attributes, [:geometry, :interp_resolution], [:xg, :yg]) do geom, intp
        (xmin, ymin), (xmax, ymax) = extrema(geom)
        return LinRange(xmin, xmax, intp[1]), LinRange(ymin, ymax, intp[2])
    end

    map!(p.attributes, [:extrapolation, :positions, :data],
         :padded_pos_data_bb) do ext, pos, dat
        return ext(pos, dat)
    end

    map!(p.attributes, [:data, :colorrange], :_colorrange) do data, crange
        if crange isa Makie.Automatic
            return Makie.extrema_nan(data)
        else
            return crange
        end
    end

    if p.interpolation[] isa DelaunayMesh
        # TODO, delaunay works very differently from the other interpolators, so we can't switch interactively between them
        map!(delaunay_mesh, p.attributes, :positions, :delaunay_mesh)

        mesh!(p, p.delaunay_mesh; color=p.data, colorrange=p.colorrange,
              colormap=p.colormap,
              shading=NoShading)
    else
        map!(p.attributes, [:xg, :yg, :geometry], :mask) do xg, yg, geometry
            pts = Point2f.(xg' .* ones(length(yg)), ones(length(xg))' .* yg)
            return in.(pts, Ref(geometry))
        end
        map!(p.attributes, [:interpolation, :xg, :yg, :padded_pos_data_bb, :mask],
             :data_interpolated) do interpolation, xg, yg, (points, data, _, _), mask
            z = interpolation(xg, yg, points, data; mask=mask)
            #            z[mask] .= NaN
            return z
        end

        p.plotfnc![](p, p.attributes, p.xg, p.yg, p.data_interpolated;)#(p.plotfnc_kwargs_names[] .=>

        # we can only do contour plot DelaunayMesh is not used, as there is no explicit interpolation to base contour on
        if !(p.interpolation isa NullInterpolator) && p.contours[] !== false
            contourdefaults = (; color=(:black, 0.5), linestyle=:dot, levels=6)
            apply_defaults!(p, :contours, :contour_attributes, contourdefaults)
            contour!(p, p.contour_attributes[], p.xg, p.yg, p.data_interpolated;)
        end
    end

    # plot a scatter plot at each position?
    if p.label_scatter[] !== false
        scatterdefaults = (; strokecolor=:black, strokewidth=1, colormap=p.colormap,
                           colorrange=p.colorrange, markersize=p.markersize)
        apply_defaults!(p, :label_scatter, :labelscatter_attributes, scatterdefaults)
        scatter!(p, p.labelscatter_attributes[], p.positions; color=p.data)
    end

    # plot the label at each position?
    if p.labels[] !== nothing && p.label_text[] !== false
        labeldefaults = (; align=(:right, :top))
        apply_defaults!(p, :label_text, :label_attributes, labeldefaults)
        text!(p, p.label_attributes[], p.positions; text=p.labels)
    end

    return
end
function apply_defaults!(p, inp, outp, defaults)
    map!(p.attributes, inp, outp) do inp
        return inp isa Bool ? Attributes(defaults) :
               Attributes(merge(defaults, inp))
    end
    #                                                        linestyle=:dot, levels=6)
end

# Use plot_fcn colormap, but not contour, text or scatter
Makie.extract_colormap(plot::TopoPlot) = Makie.extract_colormap(plot.plots[1])
