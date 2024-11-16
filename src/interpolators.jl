"""
Interface for all types <: Interpolator:

    interpolator = Interpolator(; kw_specific_to_interpolator)
    interpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}
"""
abstract type Interpolator end

"""
    CloughTocher(fill_value=NaN, tol=1e-6, maxiter=400, rescale=false)

Piecewise cubic, C1 smooth, curvature-minimizing interpolant in 2D.
Find more detailed docs in [CloughTocher2DInterpolation.jl](https://github.com/fatteneder/CloughTocher2DInterpolation.jl).

This is the default interpolator in MNE-Python.
"""
@with_kw struct CloughTocher <: Interpolator
    fill_value::Float64 = NaN
    tol::Float64 = 1e-6
    maxiter::Int = 400
    rescale::Bool = false
end

function (ct::CloughTocher)(xrange::LinRange, yrange::LinRange,
                            positions::AbstractVector{<:Point{2}},
                            data::AbstractVector{<:Number}; mask=nothing)
    posMat = Float64.(vcat([[p[1], p[2]] for p in positions]...))
    interp = CloughTocher2DInterpolation.CloughTocher2DInterpolator(posMat, data;
                                                                    tol=ct.tol,
                                                                    maxiter=ct.maxiter,
                                                                    rescale=ct.rescale)

    out = fill(NaN, size(mask))

    x = (xrange)' .* ones(length(yrange))
    y = ones(length(xrange))' .* (yrange)

    icoords = hcat(x[:], y[:])'
    if isnothing(mask)
        out .= interp(icoords)
    else
        out[mask[:]] .= interp(icoords[:, mask[:]])
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

function (sp::SplineInterpolator)(xrange::LinRange, yrange::LinRange,
                                  positions::AbstractVector{<:Point{2}},
                                  data::AbstractVector{<:Number}; mask=nothing)
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

# TODO how to properly integrated delauny with the interpolation interface,
# if the actually interpolation happens inside the plotting framework (or even on the GPU for (W)GLMakie).

"""
    DelaunayMesh()

Creates a delaunay triangulation of the points and linearly interpolates between the vertices of the triangle.
Really fast interpolation that happens on the GPU (for GLMakie), so optimal for exploring larger timeseries.

!!! warning
    `DelaunayMesh` won't allow you to add a contour plot to the topoplot.

!!! danger
    `DelaunayMesh` will not behave accurately if rendered via CairoMakie, because Cairo (and SVG in general)
    does not support color maps on meshes.  The color within each triangle will be based only on the values 
    at the vertices, which causes inaccurate visuals.
"""
struct DelaunayMesh <: Interpolator
end

(::DelaunayMesh)(positions::AbstractVector{<:Point{2}}) = delaunay_mesh(positions)

function delaunay_mesh(positions::AbstractVector{<:Point{2}})
    t = triangulate(positions) # triangulate them!   #
    simp = Int.(collect(reshape(t._triangles, 3, :)'))
    m = GeometryBasics.Mesh(Makie.to_vertices(positions), Makie.to_triangles(simp))

    return m
end

"""
    ScatteredInterpolationMethod(InterpolationMethod)

Container to specify a `InterpolationMethod` from [`ScatteredInterpolation.jl`]().
E.g. ScatteredInterpolationMethod(Shepard(P=4))
"""
@with_kw struct ScatteredInterpolationMethod <: Interpolator
    method::ScatteredInterpolation.InterpolationMethod = Shepard(4)
end

function (sim::ScatteredInterpolationMethod)(xrange::LinRange, yrange::LinRange,
                                             positions::AbstractVector{<:Point{2}},
                                             data::AbstractVector{<:Number}; mask=nothing)
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
    NaturalNeighboursMethod(; method=Sibson(1), kwargs...)

Interpolator that uses the [NaturalNeighbours.jl](https://github.com/DanielVandH/NaturalNeighbours.jl) package
to interpolate the data.  This uses Delaunay triangulations and 
the corresponding Voronoi diagram to interpolate the data, and offers
a variety of methods like `Sibson(::Int)`, `Nearest()`, and `Triangle()`.

The advantage of Voronoi-diagram based methods is that they are more robust to 
irregularly distributed datasets and some discontinuities, which may throw off 
some polynomial based methods as well as independent distance weighting (kriging). 
See [this Discourse post](https://discourse.julialang.org/t/ann-naturalneighbours-jl-natural-neighbour-interpolation-and-derivative-generation/99164/11) for more information on why NaturalNeighbours are cool! 

To access the methods easily, you should run `using NearestNeighbours`.

See the [NaturalNeighbours documentation](https://github.com/DanielVandH/NaturalNeighbours.jl) for more details.

This method is fully configurable and will forward all arguments to the relevant NaturalNeighbours.jl functions.
To understand what the methods do, see the documentation for [`NaturalNeighbours.jl`](https://github.com/DanielVandH/NaturalNeighbours.jl).

## Keyword arguments

The main keyword argument to look at here is `method`, which is the method
to use for the interpolation.  The other keyword arguments are simply forwarded 
to NaturalNeighbours.jl's interpolator.

$(Makie.DocStringExtensions.FIELDS)
"""
@with_kw struct NaturalNeighboursMethod <: Interpolator
    "The method to use for the interpolation.  Defaults to `Sibson(1)."
    method::NaturalNeighbours.AbstractInterpolator = NaturalNeighbours.Sibson{1}()
    "Whether to use multithreading when interpolating.  Defaults to `true`."
    parallel::Bool = true
    "Whether to project the data onto the Delaunay triangulation.  Defaults to `true`."
    project::Bool = true
    "The method to use for the differentiation.  Defaults to `Direct()`.  May be `Direct()` or `Iterative()`."
    derivative_method::NaturalNeighbours.AbstractDifferentiator = NaturalNeighbours.Direct()
    "Whether to use cubic terms for estimating the second order derivatives. Only relevant for derivative_method == Direct()."
    use_cubic_terms::Bool = true
    "The weighting parameter used for estimating the second order derivatives. Only relevant for derivative_method == Iterative()."
    alpha::Real = 0.1
end

function NaturalNeighboursMethod(method::NaturalNeighbours.AbstractInterpolator)
    return NaturalNeighboursMethod(; method)
end

function (alg::NaturalNeighboursMethod)(xrange::AbstractRange, yrange::AbstractRange,
                                        positions::AbstractVector{<:Point{2}},
                                        data::AbstractVector{<:Number};
                                        mask=nothing)
    @assert length(positions) == length(data) "Positions (length $(length(positions))) and data (length $(length(data))) must have the same length."
    # First, create the triangulated interpolator
    interpolator = NaturalNeighbours.interpolate(first.(positions), last.(positions), data;
                                                 derivatives=true,
                                                 method=alg.derivative_method,
                                                 use_cubic_terms=alg.use_cubic_terms,
                                                 alpha=alg.alpha,
                                                 parallel=alg.parallel,)
    # Then, interpolate the data at the grid points.
    nx, ny = length(xrange), length(yrange)
    x_values = vec([x for x in xrange, _ in yrange])
    y_values = vec([y for _ in xrange, y in yrange])
    z_values = interpolator(x_values, y_values;
                            method=alg.method,
                            parallel=alg.parallel,
                            project=alg.project,)
    # Reshape the data into a matrix.
    gridded = reshape(z_values, nx, ny)
    # Mask off if necessary.
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

function (ni::NullInterpolator)(xrange::LinRange, yrange::LinRange,
                                positions::AbstractVector{<:Point{2}},
                                data::AbstractVector{<:Number}; mask=nothing)
    return fill(NaN, length(xrange), length(yrange))
end
