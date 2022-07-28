@recipe(TopoPlot, data, positions) do scene
    return Attributes(
        colormap = Reverse(:RdBu),
        colorrange = Makie.automatic,
        sensors = true,
        interpolation = ClaughTochter(),
        bounding_geometry = Circle,
        padding = 0.1,
        pad_value = 0.0,
        resolution = (512, 512),
        labels = nothing,
        label_text = false,
        label_scatter = false,
        contours = false
    )
end

"""
    topoplot(data::Vector{<:Real}, positions::Vector{<: Point2})

Creates an irregular interpolation for each `data[i]` point at `positions[i]`.

# Attributes

* `colormap = Reverse(:RdBu)`
* `colorrange = automatic`
* `labels::Vector{<:String}` = nothing: names for each data point
* `interpolation::Interpolator = ClaughTochter()`: Applicable interpolators are $(join(subtypes(TopoPlots.Interpolator), ", "))
* `bounding_geometry = Circle`: the geometry added to the points, to create a smooth boundary. Can be `Rect` or `Circle`.
* `padding = 0.1`: padding applied to `bounding_geometry`
* `pad_value = 0.0`: data value filled in for each added position from `bounding_geometry`
* `resolution = (512, 512)`: resolution of the interpolation
* `label_text = false`:
    * true: add text plot for each position from `labels`
    * NamedTuple: Attributes get passed to the Makie.text! call.
* `label_scatter = false`:
    * true: add point for each position with default attributes
    * NamedTuple: Attributes get passed to the Makie.scatter! call.
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
    error("Attribute $(name) has the wrong type: $(typeof(value)).
          Use either a bool to enable/disable plotting with default attributes,
          or a NamedTuple with attributes getting passed down to the plot command.")
end

macro plot_or_defaults(var, defaults)
    return :(plot_or_defaults($(esc(var)), $(esc(defaults)), $(QuoteNode(var))))
end

get_bounding_rect(rect::Rect) = rect

function get_bounding_rect(circ::Circle)
    xmin, ymin = minimum(circ)
    xmax, ymax = maximum(circ)
    Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
end

function get_bounded(rect, positions, data, padding, pad_value)
    bb_xy = decompose(Point2f, rect)
    bb_v = fill(pad_value, 4)
    padding ≥ 0 || error("cannot deal with negative padding")
    allunique(positions) || error("positions must be unique")
    if padding == 0
        i = findall(∈(positions), bb_xy)
        deleteat!(bb_xy, i)
        deleteat!(bb_v, i)
    end
    append!(bb_xy, positions)
    append!(bb_v, data)
    return bb_xy, bb_v
end

function Makie.plot!(p::TopoPlot)
    npositions = Observable(0; ignore_equal_values=true)
    # positions changes with with data together since it gets into convert_arguments
    positions = lift(identity, p.positions; ignore_equal_values=true)
    geometry = lift(enclosing_geometry, p.bounding_geometry, positions, p.padding; ignore_equal_values=true)
    p.geometry = geometry # store geometry in plot object, so others can access it
    bounding_box = lift(get_bounding_rect, geometry)
    bounded = lift(get_bounded, bounding_box, positions, p.data, p.padding, p.pad_value)

    xg = Observable(LinRange(0f0, 1f0, p.resolution[][1]); ignore_equal_values=true)
    yg = Observable(LinRange(0f0, 1f0, p.resolution[][2]); ignore_equal_values=true)

    f = onany(geometry, p.resolution) do geom, resolution
        xmin, ymin = minimum(geom)
        xmax, ymax = maximum(geom)
        xg[] = LinRange(xmin, xmax, resolution[1])
        yg[] = LinRange(ymin, ymax, resolution[2])
        return
    end
    notify(p.resolution) # trigger above (we really need `update=true` for onany)

    data = lift(p.interpolation, xg, yg, bounded, geometry) do interpolation, xg, yg, (points, data), geometry
        z = interpolation(xg, yg, points, data)
        if geometry isa Circle
            c = geometry.center
            r = geometry.r
            out = [norm(Point2f(x, y) - c) > r for x in xg, y in yg]
            z[out] .= NaN
        end
        return z
    end

    heatmap!(p, xg, yg, data, colormap=p.colormap, colorrange=p.colorrange, interpolate=true)
    contours = to_value(p.contours)
    attributes = @plot_or_defaults contours Attributes(color=(:black, 0.5), linestyle=:dot, levels=6)
    if !isnothing(attributes)
        contour!(p, xg, yg, data; attributes...)
    end
    label_scatter = to_value(p.label_scatter)
    attributes = @plot_or_defaults label_scatter Attributes(markersize=5, color=p.data, colormap=p.colormap, colorrange=p.colorrange, strokecolor=:black, strokewidth=1)
    if !isnothing(attributes)
        scatter!(p, p.positions; attributes...)
    end
    if !isnothing(p.labels[])
        label_text = to_value(p.label_text)
        attributes = @plot_or_defaults label_text Attributes(align=(:right, :top))
        if !isnothing(attributes)
            text!(p, p.positions, text=p.labels; attributes...)
        end
    end
    return
end

"""
    enclosing_geometry(G::Type{<: Geometry}, positions, enlarge=0.0)

Returns the Geometry of Type `G`, that best fits all positions.
The Geometry can be enlarged by 1.x, so e.g. `enclosing_geometry(Circle, positions, 0.1)` will return a Circle that encloses all positions with a padding of 10%.
"""
function enclosing_geometry(::Type{Circle}, positions, enlarge=0.0)
    middle = mean(positions)
    radius, idx = findmax(x-> norm(x .- middle), positions)
    return Circle(middle, radius * (1 + enlarge))
end

function enclosing_geometry(::Type{Rect}, positions, enlarge=0.0)
    rect = Rect2f(positions)
    w = widths(rect)
    padded_w = w .* (1 + 2enlarge)
    mini = minimum(rect) .- ((padded_w .- w) ./ 2)
    return Rect2f(mini, padded_w)
end
