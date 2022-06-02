@recipe(TopoPlot, positions, data) do scene
    return Attributes(
        colormap = Reverse(:RdBu),
        colorrange = Makie.automatic,
        sensors = true,
        labels = nothing,
        levels = 6,
        linecolor = (:black, 0.5),
        interpolation = spline2d_mne
    )
end

function Makie.plot!(p::TopoPlot)
    if p.interpolation[] == delaunay_mesh
        npositions = Observable{Int}(0; ignore_equal_values=true)
        m = lift(p.positions) do positions
            dm = delaunay_mesh(positions)
            npositions[] = length(coordinates(dm))
            return dm
        end
        d = lift(pad_data, p.data, npositions, 0.0)
        mesh!(p, m, color=d, colorrange=p.colorrange, colormap=p.colormap, shading=false)
    else
        xg_yg_data = lift(p.positions, p.data, p.interpolation) do positions, data, interpolation
            interpolation(positions, data, pad=0.1)
        end
        xg = @lift $xg_yg_data[1]
        yg = @lift $xg_yg_data[2]
        data = @lift $xg_yg_data[3]

        heatmap!(p, xg, yg, data, colormap=p.colormap, colorrange=p.colorrange, interpolate=true)

        # mesh(Circle(Point2f(middle), radius), shading=false, color=rotl90(mat), colormap=Reverse(:RdBu), axis=(aspect=DataAspect(),), colorrange=(-0.7, 0.7), interpolate=true)
        contour!(p, xg, yg, data, color=p.linecolor, linestyle=:dot, levels=p.levels)
        # scatter!(ax, X, Y,color=(:black, 0.5)) # projection
    end
    if !isnothing(p.labels[])
        # text!(p, p.labels, position=p.positions, align=(:center, :center))
        scatter!(p, p.positions, markersize=5, color=p.data, colormap=p.colormap, colorrange=p.colorrange, strokecolor=:black, strokewidth=1)
    end
    return
end
