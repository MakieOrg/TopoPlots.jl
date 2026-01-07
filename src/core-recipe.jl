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

    # positions changes with with data together since it gets into convert_arguments

    @debug p.attributes
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
        #    getindex.(Ref(kwargs_all), p.plotfnc_kwargs_names[]))...)

        contourdefaults = (; color=(:black, 0.5), linestyle=:dot, levels=6)

        if p.interpolation isa NullInterpolator || p.contours[] == false
        else
            apply_defaults!(p, :contours, :contour_attributes, contourdefaults)
            contour!(p, p.contour_attributes[], p.xg, p.yg, p.data_interpolated;)
        end
    end

    map!(p.attributes, [:label_scatter, :markersize, :data, :colormap, :colorrange],
         :labelscatter_attributes) do label_scatter, markersize, data, colormap, colorrange
        attr = (; strokecolor=:black, strokewidth=1, color=data,
                colormap=colormap, colorrange=colorrange, markersize=markersize)
        if !(label_scatter isa Bool)
            attr = merge(attr, label_scatter)
        end
        return Attributes(attr)
    end

    scatter!(p, p.labelscatter_attributes[], p.positions)

    if !isnothing(p.labels[])
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
