using Dierckx
using ColorSchemes
using GeometryTypes
using Statistics
using TimerOutputs
using AlgebraOfGraphics
using CategoricalArrays
using PyMNE
using Makie
using TopoPlots
using Test

using PyMNE
using GLMakie
positions = TopoPlots.defaultLocations()

topoplot(rand(length(positions)),positions, axis=(aspect=DataAspect(),))
