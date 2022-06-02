using Makie.GeometryBasics: origin, radius

function enclosing_geometry(::Type{Circle}, positions, enlarge=0.0)
    middle = mean(positions)
    radius, idx = findmax(x-> norm(x .- middle), positions)
    return Circle(middle, radius * (1 + enlarge))
end

function pad_boundary(::Type{Geometry}, positions, enlarge=0.2) where Geometry
    c = enclosing_geometry(Geometry, positions, enlarge)
    return vcat(positions, decompose(Point2f, c))
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

function spline2d_mne(positions, data; pad=0.01, xres=512, yres=xres)
    c = enclosing_geometry(Circle, positions, pad)
    middle = origin(c)
    r = radius(c)
    interp = PyMNE.viz.topomap._GridData([first.(positions) last.(positions)], "head", [middle...], [r, r], "mean")
    interp.set_values(data)
    pad_amount = maximum(widths(c)) .* pad
    xmin, ymin = minimum(c)
    xmax, ymax = maximum(c)
    xg = LinRange(xmin - pad_amount, xmax + pad_amount, xres)
    yg = LinRange(ymin - pad_amount, ymax + pad_amount, yres)
    # the xg' * ones is a shorthand for np.meshgrid
    return xg, yg, interp.set_locations( ones(length(xg))' .* yg, xg' .* ones(length(yg)))()
end

function claugh_tochter(positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number}; pad=0.1, xres=512, yres=xres)
    points = pad_boundary(Circle, positions, pad)
    rect = Rect2f(points)
    xmin, ymin = minimum(rect)
    xmax, ymax = maximum(rect)
    xg = LinRange(xmin, xmax, 512)
    yg = LinRange(ymin, ymax, 512)
    data_padded = pad_data(data, points, 0.0)
    interp = SciPy.interpolate.CloughTocher2DInterpolator(Tuple.(points), data_padded)
    return xg, yg, interp(xg' .* ones(length(yg)), ones(length(xg))' .* yg)'
end

function spline2d(positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number}; pad=0.2, xres=512, yres=xres)
    # calculate 2D spline (Dierckx)
    # get extrema and extend by 20%
    points = pad_boundary(Circle, positions, pad)
    data_padded = pad_data(data, points, 0.0)
    x, y = first.(points), last.(points)
    spl = Spline2D(y, x, data_padded; kx=2, ky=2, s=0.5) # s = smoothing parameter, kx/ky = spline order
    # generate and evaluate a grid
    xg = LinRange(extrema(x)..., xres)
    yg = LinRange(extrema(y)..., yres)
    return xg, yg, (evalgrid(spl, yg, xg)') # evaluate the spline at the grid locs
end

function delaunay_mesh(positions::AbstractVector{<: Point{2}}; pad=0.1)
    points = pad_boundary(Circle, positions, pad)
    m = delaunay(convert(Matrix{Float64}, hcat(first.(points), last.(points))))
    return GeometryBasics.Mesh(Makie.to_vertices(m.points), Makie.to_triangles(m.simplices))
end
