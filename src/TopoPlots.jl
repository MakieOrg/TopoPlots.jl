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

assetpath(files...) = normpath(joinpath(dirname(@__DIR__), "assets", files...))

# Write your package code here.
include("interpolators.jl")
include("recipes.jl")
include("eeg.jl")

# Interpolators
export ClaughTochter, SplineInterpolator, DelaunayMesh

end
