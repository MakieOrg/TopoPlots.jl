
#=
Interface for interpolators:

    interpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}
=#

"""
    ClaughTochter(fill_value=NaN, tol=nothing, maxiter=nothing, rescale=nothing)

Uses [SciPy.interpolate.CloughTocher2DInterpolator](https://docs.scipy.org/doc/scipy/reference/generated/scipy.interpolate.CloughTocher2DInterpolator.html) under the Hood.
"""
@with_kw struct ClaughTochter
    fill_value::Float64 = NaN
    tol::Union{Nothing, Float64} = nothing
    maxiter::Union{Nothing, Int} = nothing
    rescale::Union{Nothing, Bool} = nothing
end


# https://docs.scipy.org/doc/scipy/reference/generated/scipy.interpolate.CloughTocher2DInterpolator.html
function (ct::ClaughTochter)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})
    # TODO hand down parameters from ct
    interp = SciPy.interpolate.CloughTocher2DInterpolator(Tuple.(positions), data)
    return collect(interp(xrange' .* ones(length(yrange)), ones(length(xrange))' .* yrange)')
end

"""
    SplineInterpolator(;kx=2, ky=2, smoothing=0.5)

Uses Dierckx.Spline2D for interpolation.
"""
@with_kw struct SplineInterpolator
    # spline order
    kx::Int = 2
    ky::Int = 2
    smoothing::Float64 = 0.5
end

function (sp::SplineInterpolator)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})
    # calculate 2D spline (Dierckx)
    # get extrema and extend by 20%
    x, y = first.(positions), last.(positions)
    spl = Spline2D(y, x, data; kx=sp.kx, ky=sp.ky, s=sp.smoothing)
    # evaluate the spline at the grid locs
    return evalgrid(spl, xrange, yrange)'
end


# TODO how to properly integrade delauny with the interpolation interface,
# if the actualy interpolation happens inside the plotting framework (or even on the GPU for (W)GLMakie).
struct DelaunayMesh
end

(::DelaunayMesh)(positions::AbstractVector{<: Point{2}}) = delaunay_mesh(positions)

function delaunay_mesh(positions::AbstractVector{<: Point{2}})
    m = delaunay(convert(Matrix{Float64}, hcat(first.(positions), last.(positions))))
    return GeometryBasics.Mesh(Makie.to_vertices(m.points), Makie.to_triangles(m.simplices))
end



#=
 MNE was too badly documented to use the internal `_GridData` interpolation struct correctly.
 Using `claugh_tochter` from SciPy, which is what `_GridData` uses internally, has been much easier.
=#

# function spline2d_mne(positions, data; pad=0.01, xres=512, yres=xres)
#     c = enclosing_geometry(Circle, positions, pad)
#     middle = origin(c)
#     r = radius(c)
#     interp = PyMNE.viz.topomap._GridData([first.(positions) last.(positions)], "head", [middle...], [r, r], "mean")
#     interp.set_values(data)
#     pad_amount = maximum(widths(c)) .* pad
#     xmin, ymin = minimum(c)
#     xmax, ymax = maximum(c)
#     xg = LinRange(xmin - pad_amount, xmax + pad_amount, xres)
#     yg = LinRange(ymin - pad_amount, ymax + pad_amount, yres)
#     # the xg' * ones is a shorthand for np.meshgrid
#     return xg, yg, interp.set_locations( ones(length(xg))' .* yg, xg' .* ones(length(yg)))()
# end
