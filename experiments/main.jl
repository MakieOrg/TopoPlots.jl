using CoordinateTransformations, GLMakie, LinearAlgebra
# the sensors along the sagital plane
sagital_percent = Dict("nasion" => 0, "fpz" => 10, "fz" => 30, "cz" => 50, "pz" => 70, "oz" => 90, "inion" => 100)
sagital = Dict(k => Point3f(CartesianFromSpherical()(Spherical(1, π/2, π*p/100))) for (k, p) in sagital_percent)

# the coronal plane
coronal_percent = ("t9" => 0, "t3" => 10, "c3" => 30, "cz" => 50, "c4" => 70, "t4" => 90, "t10" => 100)
coronal = Dict(k => Point3f(CartesianFromSpherical()(Spherical(1, π, π*p/100))) for (k, p) in coronal_percent)

# horizontal
horizontal_percent = ("fp1" => 5, "f7" => 15, "t5" => 35, "o1" => 45, "oz" => 50, "o2" => 55, "t6" => 65, "f8" => 85, "fp2" => 95)
horizontal = Dict(k => Point3f(CartesianFromSpherical()(Spherical(1, 2π*p/100 + π/2, π/10))) for (k, p) in horizontal_percent)

# all the middle sensors
other = Dict("f3" => normalize((horizontal["f7"] + sagital["fz"]) ./ 2),
             "f4" => normalize((horizontal["f8"] + sagital["fz"]) ./ 2),
             "p3" => normalize((horizontal["t5"] + sagital["pz"]) ./ 2),
             "p4" => normalize((horizontal["t6"] + sagital["pz"]) ./ 2)
          )

# the sensor coordinates in 2D
placings2d = Dict(k => Point2f(v) for (k, v) in merge(sagital, coronal, horizontal, other))

# getting some example data
using TopoPlots
using Statistics
data, positions = TopoPlots.example_data()
data = data[:, 340, 1]

# rows front to back 
# XXX why are we using Tx here instead of the modern corresponding C/P aliases?
channels = ["fp1", "fp2", 
            "f7", "f3", "fz", "f4", "f8",
            "t3", "c3", "cz", "c4", "t4",
            "t5", "p3", "pz", "p4", "t6",
            "o1", "o2"]

# pull out nearest neighbors to 10/20 system
idx = [63, 64, 
      [62, 54], [54, 43], 31, [32, 44], [44, 55],
      52, 27, 4, 21, 46,
      60, 51, 24, 47, 57,
      59, 58]

plotdat = [middle(data[i]) for i in idx]
example_data = Dict(Pair.(channels, plotdat))

# getting the example data and its 10-20 locations matched
d = Dict(placings2d[k] => v for (k,v) in example_data)
data = collect(values(d))
xy = NTuple{2, Float64}.(keys(d))

# interpolation in 3D
using GeoStats
𝒟 = georef((; data), xy)
# dims = (512,512)
dims = (100,100)
𝒢 = CartesianGrid((-1.,-1.), (1.,1.); dims)
problem = EstimationProblem(𝒟, 𝒢, :data)

using StaticArrays
import Distances.Metric
struct MyDistance <: Metric end
function (dist::MyDistance)(p1, p2) 
    ps = Vector{SVector{3, Float64}}(undef, 2)
    for (i, p) in enumerate((p1, p2))
        v = sum(abs2, p)
        v > 1 && return NaN
        z = sqrt(1 - v)
        ps[i] = SVector(p..., z)
    end
    c² = sum(abs2, only(diff(ps)))
    2atan(sqrt(c²/(4 - c²)))
end
solver = LWR(:data => (distance=MyDistance(), weightfun = h -> exp(-30*h^2)))
# solver = IDW(:data => (distance=MyDistance(), power = 1)) not so good
solution = solve(problem, solver)

# plot it
xs = range(-1, 1, dims[1])
v = reshape(values(solution).data, dims)
fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect())
heatmap!(ax, xs, xs, v, colormap = :redsblues)
contour!(ax, xs, xs, v, color = :white, levels=6)
scatter!(ax, xy, color = data, colormap = :redsblues, strokecolor = :black, strokewidth = 1)
lines!(ax, Circle(Point2f(0,0), 1), color = :black, linewidth = 2)





