using TopoPlots, GLMakie, JLD2
using Test

example_data = JLD2.load(joinpath(@__DIR__, "example.jld2"))
pos = example_data["pos2"]
data = example_data["data"]
X, Y = pos[:,1],pos[:,2]
TopoPlots.topoplot(Point2f.(X, Y), data[:,351,1], labels=string.(1:length(X)))
