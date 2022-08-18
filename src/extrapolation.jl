
"""
    enclosing_geometry(G::Type{<: Geometry}, positions, scale=1.0)

Returns the Geometry of Type `G`, that best fits all positions.
The Geometry can be enlarged by 1.x, so e.g. `enclosing_geometry(Circle, positions, 0.1)` will return a Circle that encloses all positions with a padding of 10%.
"""
function enclosing_geometry(::Type{Circle}, positions, scale=1.0)
    middle = mean(positions)
    radius, idx = findmax(x-> norm(x .- middle), positions)
    return Circle(middle, radius * scale)
end

function enclosing_geometry(::Type{Rect}, positions, scale=1.0)
    rect = Rect2f(positions)
    mini = minimum(rect)
    w = widths(rect)
    middle = mini .+ (w ./ 2)
    scaled_w = w .* scale
    return Rect2f(middle .- (scaled_w ./ 2), scaled_w)
end

points2mat(points) = vcat(first.(points)', last.(points)')
mat2points(mat) = Point2f.(view(mat, 1, :), view(mat, 2, :))

@with_kw struct GeomExtrapolation{T}
    method::T = Shepard() # extrapolation method
    scale::Float64 = 3.0 # the amount to grow the boundingbox for adding the extra points
    geometry::Any = Rect
end

function (re::GeomExtrapolation)(positions, data)
    bounding_geometry = enclosing_geometry(re.geometry, positions, 1.0)
    bounding_geometry_ext = enclosing_geometry(re.geometry, positions, re.scale)
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
