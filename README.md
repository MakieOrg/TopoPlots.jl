# TopoPlots

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://MakieOrg.github.io/TopoPlots.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://MakieOrg.github.io/TopoPlots.jl/dev)
[![Build Status](https://github.com/MakieOrg/TopoPlots.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/MakieOrg/TopoPlots.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/MakieOrg/TopoPlots.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/MakieOrg/TopoPlots.jl)


A package for creating topoplots from data that were measured on arbitrarily positioned sensors.

Quickstart:
```julia
using TopoPlots, CairoMakie
topoplot(rand(10), rand(Point2f, 10); contours=(color=:white, linewidth=2), label_scatter=true, bounding_geometry=Rect)
```
![](https://user-images.githubusercontent.com/1010467/176476327-4d29d1db-456d-4148-89f1-fa84796dc14b.png)


```julia
using GLMakie
data, positions = TopoPlots.example_data()
eeg_topoplot(data[:, 340, 1]; positions=positions)
```
![](https://user-images.githubusercontent.com/1010467/175339668-56646201-1a1d-4484-bc44-2f0a41df98c1.png)
