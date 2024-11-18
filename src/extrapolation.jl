
"""
    enclosing_geometry(G::Type{<: Geometry}, positions, enlarge=1.0)

Returns the Geometry of Type `G`, that best fits all positions.
The Geometry can be enlarged by 1.x, so e.g. `enclosing_geometry(Circle, positions, 0.1)` will return a Circle that encloses all positions with a padding of 10%.
"""
function enclosing_geometry(::Type{Circle}, positions, enlarge=1.0)
    middle = mean(positions)
    radius, idx = findmax(x -> norm(x .- middle), positions)
    return Circle(middle, radius * enlarge)
end

function enclosing_geometry(::Type{Rect}, positions, enlarge=1.0)
    rect = Rect2f(positions)
    mini = minimum(rect)
    w = widths(rect)
    middle = mini .+ (w ./ 2)
    scaled_w = w .* enlarge
    return Rect2f(middle .- (scaled_w ./ 2), scaled_w)
end

function enclosing_geometry(geometry::GeometryPrimitive, positions, enlarge=1.0)
    # ignore positions/enlarge, since we already have a concrete geometry
    return geometry
end

function enclosing_geometry(type, positions, enlarge=1.0)
    return error("Wrong type for `bounding_geometry`: $(type)")
end

points2mat(points) = vcat(first.(points)', last.(points)')
mat2points(mat) = Point2f.(view(mat, 1, :), view(mat, 2, :))

"""
    GeomExtrapolation(
        method = Shepard(), # extrapolation method
        geometry = Rect, # the geometry to fit around the points
        enlarge = 3.0 # the amount to grow the bounding geometry for adding the extra points
    )

Takes positions and data, and returns points and additional datapoints on an enlarged bounding geometry:
```julia
extra = GeomExtrapolation()
extra_positions, extra_data, bounding_geometry, bounding_geometry_enlarged = extra(positions, data)
```
"""
@with_kw struct GeomExtrapolation{T}
    method::T = Shepard() # extrapolation method
    enlarge::Float64 = 3.0 # the amount to grow the boundingbox for adding the extra points
    geometry::Any = Rect
end

function (re::GeomExtrapolation)(positions, data)
    bounding_geometry = enclosing_geometry(re.geometry, positions, 1.0)
    bounding_geometry_ext = enclosing_geometry(re.geometry, positions, re.enlarge)
    extra_points = decompose(Point2f, bounding_geometry_ext) # the points we include

    pointmat = points2mat(positions)
    data_f64 = convert(Vector{Float64}, data)
    itp = ScatteredInterpolation.interpolate(re.method, pointmat, data_f64)

    # We use the original new points from boundingobx and not the extended one, so that the distances aren't becoming way too big.
    added_points = points2mat(decompose(Point2f, bounding_geometry))
    extra_values = vec(ScatteredInterpolation.evaluate(itp, added_points))
    append!(extra_points, positions)
    append!(extra_values, data_f64)
    return extra_points, extra_values, bounding_geometry_ext, bounding_geometry
end

struct NullExtrapolation
end

function (re::NullExtrapolation)(positions, data)
    bb = Rect2f(positions)
    return positions, data, bb, bb
end
