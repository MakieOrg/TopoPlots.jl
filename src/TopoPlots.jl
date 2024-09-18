module TopoPlots

using Makie
using LinearAlgebra
using Statistics
using GeometryBasics
using GeometryBasics: origin, radius
using Parameters
using InteractiveUtils # needed for subtypes
using PrecompileTools
# Import the various interpolation packages
using Dierckx
using ScatteredInterpolation
using NaturalNeighbours # voronoi tessellation based methods
using Delaunator # DelaunayMesh
using CloughTocher2DInterpolation  # pure julia implementation of the algorithm used by scipy etc.

assetpath(files...) = normpath(joinpath(dirname(@__DIR__), "assets", files...))

"""
    example_data()

Load EEG example data.

Returns a two-tuple:
  - data: a (64, 400, 3) Float32 array of channel x timepoint x stat array.
    Timepoints correponds to samples at 500Hz from -0.3s to 0.5s relative to stimulus onset.
    Stats are mean over subjects, standard errors over subjects, and associated p-value from a t-test.
    For demonstration purposes, the first stat dimension is generally the most applicable.
  - positions: a length-64 Point2f vector of positions for each channel in data.


# Data source

Ehinger, B. V., König, P., & Ossandón, J. P. (2015).
Predictions of Visual Content across Eye Movements and Their Modulation by Inferred Information.
The Journal of Neuroscience, 35(19), 7403–7413. https://doi.org/10.1523/JNEUROSCI.5114-14.2015
"""
function example_data()
    data = Array{Float32}(undef, 64, 400, 3)
    read!(TopoPlots.assetpath("example-data.bin"), data)

    positions = Vector{Point2f}(undef, 64)
    read!(TopoPlots.assetpath("layout64.bin"), positions)
    return data, positions
end

include("interpolators.jl")
include("extrapolation.jl")
include("core-recipe.jl")
include("eeg.jl")

# Interpolators
export CloughTocher, SplineInterpolator, DelaunayMesh, NullInterpolator, ScatteredInterpolationMethod, NaturalNeighboursMethod
@deprecate ClaughTochter(args...; kwargs...) CloughTocher(args...; kwargs...) true
# Extrapolators
export GeomExtrapolation, NullExtrapolation

@setup_workload begin
    # Putting some things in `@setup_workload` instead of `@compile_workload` can reduce the size of the
    # precompile file and potentially make loading faster.
    data, positions = TopoPlots.example_data()
    @compile_workload begin
        # all calls in this block will be precompiled, regardless of whether
        # they belong to your package or not (on Julia 1.8 and higher)
       eeg_topoplot(view(data, :, 340, 1); positions)
       eeg_topoplot(data[:, 340, 1]; positions)
    end
end

end
