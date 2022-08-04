σ² = (0.07π)^2
gauss(x) = exp(-x^2/2σ²)
function angular_distance(gx, gy, gz, x, y, z)
    c² = (gx - x)^2 + (gy - y)^2 + (gz - z)^2
    return 2atan(sqrt(c²/(4 - c²)))
end
function raise2sphere(x, y)
    r² = x^2 + y^2
    z = sqrt(1 - r²)
    return (x, y, z)
end
function lwr(gx, gx², gy, gy², xyz)
    gr² = gx² + gy²
    gr² > 1 && return NaN
    gz = sqrt(1 - gr²)
    l = [angular_distance(gx, gy, gz, x, y, z) for (x, y, z) in xyz]
    w = gauss.(l)
    return mean(data, weights(w))
end
using Delaunay, StatsBase, LinearAlgebra
using TopoPlots, GLMakie
data, xy = TopoPlots.example_data()
data = data[:, 340, 1]
μ = mean(xy)
xy .-= μ
r = maximum(norm, xy)
xy ./= r/0.95105654
function fun(data, xy, ncontour, nperimeter)
    xyz = [raise2sphere(x, y) for (x,y) in xy]
    steps = range(-1, 1, length=ncontour)
    steps² = steps.^2
    v = [lwr(gx, gx², gy, gy², xyz) for (gx, gx²) in zip(steps, steps²), (gy, gy²) in zip(steps, steps²)]
    xyc = [Point2(x, y) for (j,y) in pairs(steps) for (i, x) in pairs(steps) if !isnan(v[i,j])]
    vc = filter(!isnan, v)
    xyp = decompose(Point2, Circle(zero(Point2), 1 - eps()), nperimeter)
    vp = [lwr(gx, gx^2, gy, gy^2, xyz) for (gx, gy) in xyp]
    positions = vcat(xyp, xyc)
    m = delaunay(convert(Matrix{Float64}, hcat(first.(positions), last.(positions))))
    fig = Figure()
    ax = Axis(fig[1,1], aspect = DataAspect())
    mesh!(ax, m.points, m.simplices, color = vcat(vp, vc), shading=false, colormap = :redsblues)
    contour!(ax, steps, steps, v, color = :white, levels=6)
    scatter!(ax, xy, color = data, colormap = :redsblues, strokecolor = :black, strokewidth = 1)
    fig
end
fig = fun(data, xy, 40,40)












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
dims = (50,50)
𝒢 = CartesianGrid((-1.,-1.), (1.,1.); dims)
problem = EstimationProblem(𝒟, 𝒢, :data)
import Distances.Metric
struct MyDistance <: Metric end
function (dist::MyDistance)(xy1, xy2) 
    @inbounds x1, y1 = xy1
    v = x1^2 + y1^2
    v > 1 && return Float64(π)
    z1 = sqrt(1 - v)
    @inbounds x2, y2 = xy2
    v = x2^2 + y2^2
    v > 1 && return Float64(π)
    z2 = sqrt(1 - v)
    c² = (x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2
    return 2atan(sqrt(c²/(4 - c²)))
end
solver = LWR(:data => (distance=MyDistance(), weightfun = h -> exp(-30*h^2)))
# solver = IDW(:data => (distance=MyDistance(), power = 1)) not so good
solution = solve(problem, solver)
using Interpolations
xs = range(-1, 1, dims[1])
v = reshape(values(solution).data, dims)
itp = linear_interpolation((xs, xs), v)
# itp = cubic_spline_interpolation((xs, xs), v)
xl = range(-1, 1, 512)
vl = Matrix{Float64}(undef, 512, 512)
for (i, x) in pairs(xl), (j, y) in pairs(xl)
    vl[i,j] = x^2 + y^2 > 1 ? NaN : itp(x, y)
end
fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect())
heatmap!(ax, xl, xl, vl, colormap = :redsblues)
contour!(ax, xl, xl, vl, color = :white, levels=6)
scatter!(ax, xy, color = data, colormap = :redsblues, strokecolor = :black, strokewidth = 1)
# lines!(ax, Circle(Point2f(0,0), 1), color = :black, linewidth = 2)


# plot it
xs = range(-1, 1, dims[1])
v = reshape(values(solution).data, dims)
fig = Figure()
ax = Axis(fig[1,1], aspect = DataAspect())
heatmap!(ax, xs, xs, vl, colormap = :redsblues)
contour!(ax, xs, xs, vl, color = :white, levels=6)
scatter!(ax, xy, color = data, colormap = :redsblues, strokecolor = :black, strokewidth = 1)
lines!(ax, Circle(Point2f(0,0), 1), color = :black, linewidth = 2)



using BenchmarkTools

function inside()
    r = sqrt(rand())
    α = 2π*rand()
    return r .* reverse(sincos(α))
end
function outside()
    r = sqrt(1 + rand())
    α = 2π*rand()
    return r .* reverse(sincos(α))
end
ps = map(_ -> inside(), 1:1000)
scatter(ps; axis=(aspect=DataAspect(),))
ps = map(_ -> outside(), 1:1000)
scatter!(ps)
dist = MyDistance()

@benchmark dist(inside(), inside())

p1 = [1,0,0]
p2 = normalize([-1,0,0])
acosd(normalize(p1) ⋅ normalize(p2))
asind(norm(normalize(p1) × normalize(p2)))
atand(norm(normalize(p1) × normalize(p2))/(normalize(p1) ⋅ normalize(p2)))
rad2deg(dist(p1[1:2], p2[1:2]))

σ = deg2rad(33)
p1 = normalize(rand(3))
p2 = 

dist((1,0), (1,0))

