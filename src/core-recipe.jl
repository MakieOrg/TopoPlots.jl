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
                      (plotfnc!)=heatmap!,
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
* `label_text = false`:
    * true: add text plot for each position from `labels`
    * NamedTuple: Attributes get passed to the Makie.text! call.
* `label_scatter = false`:
    * true: add point for each position with default attributes
    * NamedTuple: Attributes get passed to the Makie.scatter! call.
* `markersize = 5`: size of the points defined by positions, shortcut for label_scatter=(markersize=5,)
* `plotfnc! = heatmap!`: function to use for plotting the interpolation
* `plotfnc_kwargs_names = [:colorrange, :colormap, :interpolate]`: different `plotfnc` support different kwargs, this array contains the keys to filter the full list which is [:colorrange, :colormap, :interpolate]

* `contours = false`:
    * true: add scatter point for each position
    * NamedTuple: Attributes get passed to the Makie.contour! call.

# Example

```julia
using TopoPlots, CairoMakie
topoplot(rand(10), rand(Point2f, 10); contours=(color=:red, linewidth=2))
```
"""
topoplot

# Handle the nothing/bool/attribute situation for e.g. contours/label_scatter
plot_or_defaults(value::Bool, defaults, name) = value ? defaults : nothing
plot_or_defaults(value::Attributes, defaults, name) = merge(value, defaults)

function plot_or_defaults(value, defaults, name)
    return error("Attribute $(name) has the wrong type: $(typeof(value)).
                 Use either a bool to enable/disable plotting with default attributes,
                 or a NamedTuple with attributes getting passed down to the plot command.")
end

macro plot_or_defaults(var, defaults)
    return :(plot_or_defaults($(esc(var)), $(esc(defaults)), $(QuoteNode(var))))
end

function Makie.plot!(p::TopoPlot)
    Obs(x) = Observable(x; ignore_equal_values=true) # we almost never want to trigger updates if value stay the same
    npositions = Obs(0)

    # positions changes with with data together since it gets into convert_arguments
    positions = lift(identity, p, p.positions; ignore_equal_values=true)
    geometry = lift(enclosing_geometry, p, p.bounding_geometry, positions, p.enlarge;
                    ignore_equal_values=true)

    xg = Obs(LinRange(0.0f0, 1.0f0, p.interp_resolution[][1]))
    yg = Obs(LinRange(0.0f0, 1.0f0, p.interp_resolution[][2]))

    f = onany(p, geometry, p.interp_resolution) do geometry, interp_resolution
        (xmin, ymin), (xmax, ymax) = extrema(geometry)
        xg[] = LinRange(xmin, xmax, interp_resolution[1])
        yg[] = LinRange(ymin, ymax, interp_resolution[2])
        return
    end

    notify(p.interp_resolution) # trigger above (we really need `update=true` for onany)

    p.geometry = geometry # store geometry in plot object, so others can access it

    padded_pos_data_bb = lift(p, p.extrapolation, p.positions,
                              p.data) do extrapolation, positions, data
        return extrapolation(positions, data)
    end

    colorrange = lift(p, p.data, p.colorrange) do data, crange
        if crange isa Makie.Automatic
            return Makie.extrema_nan(data)
        else
            return crange
        end
    end

    if p.interpolation[] isa DelaunayMesh
        # TODO, delaunay works very differently from the other interpolators, so we can't switch interactively between them
        m = lift(delaunay_mesh, p, p.positions)
        mesh!(p, m; color=p.data, colorrange=colorrange, colormap=p.colormap,
              shading=NoShading)
    else
        mask = lift(p, xg, yg, geometry) do xg, yg, geometry
            pts = Point2f.(xg' .* ones(length(yg)), ones(length(xg))' .* yg)
            return in.(pts, Ref(geometry))
        end

        data = lift(p, p.interpolation, xg, yg, padded_pos_data_bb,
                    mask) do interpolation, xg, yg, (points, data, _, _), mask
            z = interpolation(xg, yg, points, data; mask=mask)
            #            z[mask] .= NaN
            return z
        end
        kwargs_all = Dict(:colorrange => colorrange, :colormap => p.colormap,
                          :interpolate => true)

        p.plotfnc![](p, xg, yg, data;
                     (p.plotfnc_kwargs_names[] .=>
                          getindex.(Ref(kwargs_all), p.plotfnc_kwargs_names[]))...)
        contours = to_value(p.contours)
        attributes = @plot_or_defaults contours Attributes(color=(:black, 0.5),
                                                           linestyle=:dot, levels=6)
        if !isnothing(attributes) && !(p.interpolation[] isa NullInterpolator)
            contour!(p, xg, yg, data; attributes...)
        end
    end
    label_scatter = to_value(p.label_scatter)
    attributes = @plot_or_defaults label_scatter Attributes(markersize=p.markersize,
                                                            color=p.data,
                                                            colormap=p.colormap,
                                                            colorrange=colorrange,
                                                            strokecolor=:black,
                                                            strokewidth=1)
    if !isnothing(attributes)
        scatter!(p, p.positions; attributes...)
    end
    if !isnothing(p.labels[])
        label_text = to_value(p.label_text)
        attributes = @plot_or_defaults label_text Attributes(align=(:right, :top))
        if !isnothing(attributes)
            text!(p, p.positions; text=p.labels, attributes...)
        end
    end
    return
end

# Use plot_fcn colormap, but not contour, text or scatter
Makie.extract_colormap(plot::TopoPlot) = Makie.extract_colormap(plot.plots[1])