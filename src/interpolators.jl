"""
Interface for all types <: Interpolator:

    interpolator = Interpolator(; kw_specific_to_interpolator)
    interpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}
"""
abstract type Interpolator end

"""
    CloughTocher(fill_value=NaN, tol=1e-6, maxiter=400, rescale=false)

Piecewise cubic, C1 smooth, curvature-minimizing interpolant in 2D.
Find more detailed docs in CloughTocher2DInterpolator.jl.

This is the default interpolator in MNE-Python
"""
@with_kw struct CloughTocher <: Interpolator
    fill_value::Float64 = NaN
    tol::Float64 = 1e-6
    maxiter::Int = 400
    rescale::Bool = false
end

function (ct::CloughTocher)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number};mask=nothing)

    	posMat = Float64.(vcat([[p[1],p[2]] for p in positions]...))
        interp = CloughTocher2DInterpolation.CloughTocher2DInterpolator(posMat, data,tol=ct.tol, maxiter=ct.maxiter, rescale=ct.rescale)

    out = fill(NaN,size(mask))

    x = (xrange)' .* ones(length(yrange))
	  y = ones(length(xrange))' .* (yrange)


	icoords = hcat(x[:],y[:])'
    if isnothing(mask)
        out .= interp(icoords)
    else
	    out[mask[:]] .= interp(icoords[:,mask[:]])
    end
    return out'

end

"""
    SplineInterpolator(;kx=2, ky=2, smoothing=0.5)

Uses [Dierckx.Spline2D](https://github.com/kbarbary/Dierckx.jl#2-d-splines) for interpolation.
"""
@with_kw struct SplineInterpolator <: Interpolator
    # spline order
    kx::Int = 2
    ky::Int = 2
    smoothing::Float64 = 0.5
end

function (sp::SplineInterpolator)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<:Point{2}}, data::AbstractVector{<:Number}; mask=nothing)
    # calculate 2D spline (Dierckx)
    # get extrema and extend by 20%
    x, y = first.(positions), last.(positions)
    spl = Spline2D(y, x, data; kx=sp.kx, ky=sp.ky, s=sp.smoothing)
    # evaluate the spline at the grid locs
    out = evalgrid(spl, xrange, yrange)'
    if .!isnothing(mask)
        out[.!mask] .= NaN
    end
    return out
end


# TODO how to properly integrade delauny with the interpolation interface,
# if the actualy interpolation happens inside the plotting framework (or even on the GPU for (W)GLMakie).

"""
    DelaunayMesh()

Creates a delaunay triangulation of the points and linearly interpolates between the vertices of the triangle.
Really fast interpolation that happens on the GPU (for GLMakie), so optimal for exploring larger timeseries.

!!! warning
    `DelaunayMesh` won't allow you to add a contour plot to the topoplot.
"""
struct DelaunayMesh <: Interpolator
end

(::DelaunayMesh)(positions::AbstractVector{<: Point{2}}) = delaunay_mesh(positions)

function delaunay_mesh(positions::AbstractVector{<: Point{2}})

    t = triangulate(positions) # triangulate them!   #
    simp = Int.(collect(reshape(t._triangles,3,:)'))
    m = GeometryBasics.Mesh(Makie.to_vertices(positions), Makie.to_triangles(simp))

    return m
end


"""
    ScatteredInterpolationMethod(InterpolationMethod)

    Container to specify a `InterpolationMethod` from ScatteredInterpolation.
    E.g. ScatteredInterpolationMethod(Shepard(P=4))
"""
@with_kw struct ScatteredInterpolationMethod <: Interpolator
    method::ScatteredInterpolation.InterpolationMethod = Shepard(4)
end

function (sim::ScatteredInterpolationMethod)(
            xrange::LinRange, yrange::LinRange,
            positions::AbstractVector{<:Point{2}}, data::AbstractVector{<:Number}; mask=nothing)
    n = length(xrange)
    X = repeat(xrange, n)[:]
    Y = repeat(yrange', n)[:]
    gridPoints = [X Y]'

    itp = ScatteredInterpolation.interpolate(sim.method, hcat(positions...), data)
    interpolated = ScatteredInterpolation.evaluate(itp, gridPoints)
    gridded = reshape(interpolated, n, n)

    if .!isnothing(mask)
        gridded[.!mask] .= NaN
    end
    return gridded

end


"""
    NullInterpolator()

Interpolator that returns "0", which is useful to display only the electrode locations + labels
"""
struct NullInterpolator <: TopoPlots.Interpolator

end

function (ni::NullInterpolator)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<:Point{2}}, data::AbstractVector{<:Number}; mask=nothing)
    return fill(NaN, length(xrange), length(yrange))
end
