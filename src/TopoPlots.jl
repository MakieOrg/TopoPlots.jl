module TopoPlots

using Makie
using PyMNE
using SciPy
using Delaunay
using Dierckx
using LinearAlgebra
using Statistics
using GeometryBasics

# Write your package code here.
include("interpolators.jl")
include("recipes.jl")

end
