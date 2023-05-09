"""
Interface for all types <: Interpolator:

    interpolator = Interpolator(; kw_specific_to_interpolator)
    interpolator(xrange::LinRange, yrange::LinRange, positions::Vector{Point2}, data::Vector{<: Real})::Matrix{<: Real}
"""
abstract type Interpolator end

"""
    ClaughTochter(fill_value=NaN, tol=1e-6, maxiter=400, rescale=false)

Piecewise cubic, C1 smooth, curvature-minimizing interpolant in 2D.
Find more detailed docs in [SciPy.interpolate.CloughTocher2DInterpolator](https://docs.scipy.org/doc/scipy/reference/generated/scipy.interpolate.CloughTocher2DInterpolator.html).
Slow, but yields the smoothest interpolation.
"""
@with_kw struct ClaughTochter <: Interpolator
    fill_value::Float64 = NaN
    tol::Float64 = 1e-6
    maxiter::Int = 400
    rescale::Bool = false
end



@with_kw struct CloughTocher <: Interpolator
    fill_value::Float64 = NaN
    tol::Float64 = 1e-6
    maxiter::Int = 400
    rescale::Bool = false
end

function (ct::CloughTocher)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})

    	posMat = Float64.(vcat([[p[1],p[2]] for p in positions]...))
        interp = CloughTocher2DInterpolation.CloughTocher2DInterpolator(posMat, data,tol=ct.tol, maxiter=ct.maxiter, rescale=ct.rescale)
x = (xrange)' .* ones(length(yrange))
	y = ones(length(xrange))' .* (yrange)

	icoords = hcat(x[:],y[:])'
	o = interp(icoords)
    return reshape(o,length(xrange),length(yrange))'
end


"""
python version, deprecated
"""
function (ct::ClaughTochter)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})

    params = Iterators.filter(((k, v),) -> !(v isa Nothing), Dict(:tol => ct.tol, :maxiter => ct.maxiter, :rescale => ct.rescale))

    interp = SciPy.interpolate.CloughTocher2DInterpolator(
        convert(Matrix{Float64},hcat(first.(positions), last.(positions))), data;
        tol=ct.tol, maxiter=ct.maxiter, rescale=ct.rescale)

    return collect(pyconvert(Matrix,interp(xrange' .* ones(length(yrange)), ones(length(xrange))' .* yrange))')
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
    simplices = delaunay(convert(Matrix{Float64}, hcat(first.(positions), last.(positions))))
    return GeometryBasics.Mesh(Makie.to_vertices(positions), Makie.to_triangles(simplices))

  # Test using VoronoiDelaunay.jl
  #  tess = DelaunayTessellation(length(positions))
  #  
  #  push!(tess,[Point2D((a.+1)...) for a in positions])
  #  simp = []
  #  extr = x->[geta(x),getb(x),getc(x)]
  #  p2p = x->(Point2f(getx(x),gety(x)))
  #  for t in tess
  #      push!(simp, GeometryBasics.Ngon(SVector{3,Point2f}(p2p.(extr(t)))))
  #  end
  #  
  #  v = Vector{typeof(simp[1])}(simp) # probably a better way to initialize the list directly ;)
  #  return GeometryBasics.Mesh(v)
end

function delaunay(vertices)
    pydelaunay = SciPy_Spatial.Delaunay(vertices)
    simplices = pyconvert(Array{Int,2}, pydelaunay.simplices)
    simplices .= simplices .+1
    return simplices

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
            positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})
    n = length(xrange)
    X = repeat(xrange, n)[:]
    Y = repeat(yrange', n)[:]
    gridPoints = [X Y]'
    
    itp = ScatteredInterpolation.interpolate(sim.method, hcat(positions...), data)
    interpolated = ScatteredInterpolation.evaluate(itp, gridPoints)
    gridded = reshape(interpolated, n, n)
    return gridded

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


"""
    NullInterpolator()

Interpolator that returns "0", which is useful to display only the electrode locations + labels
"""
struct NullInterpolator <: TopoPlots.Interpolator

end

function (ni::NullInterpolator)(
        xrange::LinRange, yrange::LinRange,
        positions::AbstractVector{<: Point{2}}, data::AbstractVector{<:Number})
    return fill(NaN, length(xrange), length(yrange))
end
