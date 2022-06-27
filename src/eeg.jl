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

const CHANNELS_10_20 = ["fp1", "f3", "c3", "p3", "o1", "f7", "t3", "t5", "fz", "cz", "pz", "fp2", "f4", "c4", "p4", "o2", "f8", "t4", "t6"]

const CHANNEL_TO_POSITION_10_20 = begin
    # We load this during precompilation, so that this gets stored as a global
    # that's immediately loaded when loading the package
    result = Matrix{Float64}(undef, 19, 2)
    read!(assetpath("layout_10_20.bin"), result)
    positions = Point2f.(result[:, 1], result[:, 2])
    Dict{String, Point2f}(zip(CHANNELS_10_20, positions))
end

"""
    labels2positions(labels)
Currently only supports 10/20 layout, by looking it up in `TopoPlots.CHANNEL_TO_POSITION_10_20`.
"""
function labels2positions(labels)
    return map(labels) do label
        key = lowercase(label)
        if haskey(CHANNEL_TO_POSITION_10_20, key)
            return CHANNEL_TO_POSITION_10_20[key]
        else
            error("Currently only 10_20 is supported. Found: $(label)")
        end
    end
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
