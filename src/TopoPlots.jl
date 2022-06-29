module TopoPlots

using Makie
using SciPy
using Delaunay
using Dierckx
using LinearAlgebra
using Statistics
using GeometryBasics
using GeometryBasics: origin, radius
using Parameters

using DataFrames
using CategoricalArrays
using AlgebraOfGraphics
using InteractiveUtils

assetpath(files...) = normpath(joinpath(dirname(@__DIR__), "assets", files...))

function example_data()
    data = Array{Float32}(undef, 64, 400, 3)
    read!(TopoPlots.assetpath("example-data.bin"), data)

    positions = Vector{Point2f}(undef, 64)
    read!(TopoPlots.assetpath("layout64.bin"), positions)
    return data, positions
end

# Write your package code here.
include("interpolators.jl")
include("core-recipe.jl")
include("eeg.jl")

# Interpolators
export ClaughTochter, SplineInterpolator, DelaunayMesh

end
