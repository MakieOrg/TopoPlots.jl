using Delaunay, StatsBase, LinearAlgebra
using TopoPlots, GLMakie, GeometryBasics

# the weighting function
gauss(x, σ) = exp(-x^2/2σ^2)

# the distance function. This calculates the angular distance in radians between two 3D cartesian points on the surface of a sphere
function angular_distance(gx, gy, gz, x, y, z)
    c² = (gx - x)^2 + (gy - y)^2 + (gz - z)^2
    return 2atan(sqrt(c²/(4 - c²)))
end

# given x and y, calculates the height from the xy plane to the upper hemisphere of the unit sphere. Returns that height as z in (x, y, z)
function raise2sphere(x, y)
    r² = x^2 + y^2
    z = sqrt(1 - r²)
    return (x, y, z)
end

# Locally Weighted Regression
function lwr(gx, gy, xyz, σ, data)
    gr² = gx^2 + gy^2
    gr² > 1 && return NaN
    gz = sqrt(1 - gr²)
    l = [angular_distance(gx, gy, gz, x, y, z) for (x, y, z) in xyz]
    w = gauss.(l, σ)
    return mean(data, weights(w))
end

# centers and scales coordinates to max_distance
function standardize!(xy; μ = mean(xy), max_distance = cos(0.1π))
    xy .-= μ
    r = maximum(norm, xy)
    xy ./= r/max_distance
    return xy
end

# concatenate coordinates from the grid with valid values, as well as from the circle perimeter
function mesh_coordinates(steps, v, xyp)
    xyc = [Point2f(x, y) for (j,y) in pairs(steps) for (i, x) in pairs(steps) if !isnan(v[i,j])]
    xy = vcat(xyp, xyc)
    m = delaunay(Matrix{Float64}(hcat(first.(xy), last.(xy))))
    return GeometryBasics.Mesh(Makie.to_vertices(m.points), Makie.to_triangles(m.simplices))
end

# concatenate valid values from the grid, as well as from the circle perimeter
function mesh_color(xyp, v, xyz, σ, data)
    vc = filter(!isnan, v)
    vp = [lwr(gx, gy, xyz, σ, data) for (gx, gy) in xyp]
    return vcat(vp, vc)
end

# function for testing only
function fun(data, positions, grid_resolution, perimeter_resolution, σ)
    xyz = [raise2sphere(x, y) for (x,y) in positions]
    steps = range(-1, 1, length=grid_resolution)
    v = [lwr(gx, gy, xyz, σ, data) for gx in steps, gy in steps]
    xyp = decompose(Point2f, Circle(zero(Point2f), 1 - 1e-6), perimeter_resolution)
    m = mesh_coordinates(steps, v, xyp)
    color = mesh_color(xyp, v, xyz, σ)
    # m = get_mesh(steps, v, perimeter_resolution, xyz, σ)
    fig = Figure()
    ax = Axis(fig[1,1], aspect = DataAspect())
    mesh!(ax, m, color = color, shading=false, colormap = :redsblues)
    contour!(ax, steps, steps, v, color = :white, levels=6)
    scatter!(ax, positions, color = data, colormap = :redsblues, strokecolor = :black, strokewidth = 1)
    fig
end

@recipe(EEGPlot, data, positions) do scene
    return Attributes(
        grid_resolution = 40,
        perimeter_resolution = 40,
        σ = 0.05π,
        colormap = Reverse(:redsblues),
    )
end

"""
    eegplot(data::Vector{<:Real}, positions::Vector{<: Point2})

Creates an irregular interpolation for each `data[i]` point at `positions[i]`.

# Attributes

* `grid_resolution = 40`
* `perimeter_resolution = 40`
* `σ = 0.05π`
* `colormap = Reverse(:redsblues)`

# Example

```julia
using TopoPlots, CairoMakie
eegplot(rand(10), rand(Point2f, 10))
```
"""
eegplot

function Makie.plot!(p::EEGPlot)
    xyz = @lift [raise2sphere(x, y) for (x,y) in $(p.positions)]
    steps = @lift range(-1, 1, length=$(p.grid_resolution))
    v = @lift [lwr(gx, gy, $xyz, $(p.σ), $(p.data)) for gx in $steps, gy in $steps]
    xyp = @lift decompose(Point2f, Circle(zero(Point2f), 1 - 1e-6), $(p.perimeter_resolution))
    m = @lift mesh_coordinates($steps, $v, $xyp)
    color = @lift mesh_color($xyp, $v, $xyz, $(p.σ), $(p.data))
    mesh!(p, m, color = color, shading=false, colormap = p.colormap)
    contour!(p, steps, steps, v, color = :red, levels=6)
    scatter!(p, p.positions, color = p.data, colormap = p.colormap, strokecolor = :black, strokewidth = 1)
end



all_data, _positions = TopoPlots.example_data()
positions = Observable(standardize!(_positions))

fig = Figure()
ax = Axis(fig[1,1], aspect=DataAspect())
sg = SliderGrid(fig[2, 1],
                (label = "data", range = 1:size(all_data, 2)),
                (label = "σ", range = range(0.01π, π, length = 100)),
                (label = "grid resolution", range = 10:100, startvalue=50), 
                (label = "perimeter resolution", range = 10:100, startvalue=50),
)
σ = sg.sliders[2].value
grid_resolution = sg.sliders[3].value
perimeter_resolution = sg.sliders[4].value
data = lift(sg.sliders[1].value) do i
    all_data[:,i,1]
end
eegplot!(ax, data, positions; σ, grid_resolution, perimeter_resolution)
display(fig)
