@recipe(EEGTopoPlot, data, labels) do scene
    return Attributes(;
        show_head = true,
        positions = Makie.automatic,
        default_theme(scene, TopoPlot)...,
        # overwrite some topoplot defaults
        label_scatter = true,
        contours = true,
    )
end

function draw_ear_nose!(parent, circle)
    # draw circle
    head_points = lift(circle) do circle
        points = decompose(Point2f, circle)
        diameter = 2GeometryBasics.radius(circle)
        middle = GeometryBasics.origin(circle)
        nose = (Point2f[(-0.05, 0.5), (0.0, 0.55), (0.05, 0.5)] .* diameter) .+ (middle,)
        push!(points, Point2f(NaN)); append!(points, nose)
        ear = (Point2f[
            (0.497, 0.0555), (0.51, 0.0775), (0.518, 0.0783),
            (0.5299, 0.0746), (0.5419, 0.0555), (0.54, -0.0055),
            (0.547, -0.0932), (0.532, -0.1313), (0.51, -0.1384),
            (0.489, -0.1199)] .* diameter)

        push!(points, Point2f(NaN)); append!(points, ear .+ middle)
        push!(points, Point2f(NaN)); append!(points, (ear .* Point2f(-1, 1)) .+ (middle,))
        return points
    end

    lines!(parent, head_points, color=:black, linewidth=3)
end

function labels2positions(labels)
    error("Not implemented yet")
end

function Makie.plot!(plot::EEGTopoPlot)
    positions = lift(plot.labels, plot.positions) do labels, positions
        if positions isa Makie.Automatic
            return labels2positions(labels)
        else
            # apply same conversion as for e.g. the scatter arguments
            return convert_arguments(Makie.PointBased(), positions)[1]
        end
    end

    tplot = topoplot!(plot, Attributes(plot), plot.data, positions; labels=plot.labels)
    draw_ear_nose!(plot, tplot.geometry)
    return
end
