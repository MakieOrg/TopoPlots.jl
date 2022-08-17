@recipe(TopoPlot, data, positions) do scene
    return Attributes(
        colormap = Reverse(:RdBu),
        colorrange = Makie.automatic,
        sensors = true,
        interpolation = ClaughTochter(),
        bounding_geometry = Circle,
        markersize = 5,
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
* `markersize = 5`: size of the points defined by positions
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

points2mat(points) = vcat(first.(points)', last.(points)')
mat2points(mat) = Point2f.(mat[1, :], mat[2, :])

function extrapolate_data(rect, positions, data)
    mini, maxi = extrema(rect)
    rect_extended = Rect(Circle(Point2f((mini .+ maxi) ./ 2), maximum(widths(rect)) * 3))
    bb_points = decompose(Point2f, rect_extended)
    pointmat = points2mat(positions)
    #
    data_f64 = convert(Vector{Float64}, data)
    itp = ScatteredInterpolation.interpolate(Shepard(), pointmat, data_f64)
    bb_values = vec(ScatteredInterpolation.evaluate(itp, points2mat(decompose(Point2f, rect))))
    append!(bb_points, positions)
    append!(bb_values, data_f64)
    return bb_points, rect_extended, bb_values
end


function Makie.plot!(p::TopoPlot)
    Obs(x) = Observable(x; ignore_equal_values=true) # we almost never want to trigger updates if value stay the same
    npositions = Obs(0)
    geometry = lift(enclosing_geometry, p.bounding_geometry, p.positions, p.padding; ignore_equal_values=true)
    p.geometry = geometry # store geometry in plot object, so others can access it

    # positions changes with with data together since it gets into convert_arguments
    positions = lift(identity, p.positions; ignore_equal_values=true)

    xg = Obs(LinRange(0f0, 1f0, p.resolution[][1]))
    yg = Obs(LinRange(0f0, 1f0, p.resolution[][2]))

    f = onany(geometry, p.resolution) do geom, resolution
        xmin, ymin = minimum(geom)
        xmax, ymax = maximum(geom)
        xg[] = LinRange(xmin, xmax, resolution[1])
        yg[] = LinRange(ymin, ymax, resolution[2])
        return
    end
    notify(p.resolution) # trigger above (we really need `update=true` for onany)
    bounding_box = lift(get_bounding_rect, geometry)
    padded_pos_rect_data = lift(extrapolate_data, bounding_box, p.positions, p.data)
    colorrange = lift(p.data, p.colorrange) do data, crange
        if crange isa Makie.Automatic
            return Makie.extrema_nan(data)
        else
            return crange
        end
    end
    if p.interpolation[] isa DelaunayMesh
        # TODO, delaunay works very differently from the other interpolators, so we can't switch interactively between them
        m = lift(delaunay_mesh, p.positions)
        mesh!(p, m, color=p.data, colorrange=colorrange, colormap=p.colormap, shading=false)
    else
        data = lift(p.interpolation, xg, yg, padded_pos_rect_data, geometry) do interpolation, xg, yg, (points, _, data), geometry
            z = interpolation(xg, yg, points, data)
            if geometry isa Circle
                c = geometry.center
                r = geometry.r
                out = [norm(Point2f(x, y) - c) > r for x in xg, y in yg]
                z[out] .= NaN
            end
            return z
        end

        heatmap!(p, xg, yg, data, colormap=p.colormap, colorrange=colorrange, interpolate=true)
        contours = to_value(p.contours)
        attributes = @plot_or_defaults contours Attributes(color=(:black, 0.5), linestyle=:dot, levels=6)
        if !isnothing(attributes) && !(p.interpolation[] isa NullInterpolator)
            contour!(p, xg, yg, data; attributes...)
        end
    end
    label_scatter = to_value(p.label_scatter)
    attributes = @plot_or_defaults label_scatter Attributes(markersize=p.markersize, color=p.data, colormap=p.colormap, colorrange=colorrange, strokecolor=:black, strokewidth=1)
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

"""
    pad_boundary(::Type{Geometry}, positions, enlarge=0.2) where Geometry

Adds new points to positions, adding the boundary from enclosing all positions with `Geometry`.
See [`TopoPlots.enclosing_geometry`](@ref) for more details about the boundary.
"""
function pad_boundary!(::Type{Geometry}, positions, enlarge=0.2) where Geometry
    c = enclosing_geometry(Geometry, positions, enlarge)
    return append!(positions, decompose(Point2f, c))
end

function pad_data(data::AbstractVector, positions::AbstractVector, value::Number)
    pad_data(data, length(positions), value)
end

function pad_data(data::AbstractVector, npositions::Integer, value::Number)
    ndata = length(data)
    if npositions == ndata
        return data
    elseif npositions < ndata
        error("To pad the data for new positions, we need more positions than data points")
    else
        vcat(data, fill(value, npositions - ndata))
    end
end
