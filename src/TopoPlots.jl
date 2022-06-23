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

# Write your package code here.
include("interpolators.jl")
include("recipes.jl")

# Interpolators
export ClaughTochter, SplineInterpolator, DelaunayMesh

end
