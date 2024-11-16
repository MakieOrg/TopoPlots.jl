
@recipe(EEG_TopoPlot, data) do scene
    return Attributes(;
        head=(color=:black, linewidth=3),
        labels=Makie.automatic,
        positions = Makie.automatic,
        # overwrite some topoplot defaults
        default_theme(scene, TopoPlot)...,
        label_scatter=true,
        contours=true,
        enlarge=1,
    )
end

"""
    eeg_topoplot(data::Vector{<: Real}, labels::Vector{<: AbstractString})

Attributes:

* `positions::Vector{<: Point} = Makie.automatic`: Can be calculated from label (channel) names. Currently, only 10/20 montage has default coordinates provided.
* `labels::AbstractVector{<:AbstractString} = Makie.automatic`: Add custom labels, when `label_text` is set to true. If `positions` is not specified, `labels` are used to look up the 10/20 coordinates.
* `head = (color=:black, linewidth=3)`: draw the outline of the head. Set to nothing to not draw the head outline, otherwise set to a namedtuple that get passed down to the `line!` call that draws the shape.
# Some attributes from topoplot are set to different defaults:
* `label_scatter = true`
* `contours = true`
* `enlarge = 1``

Otherwise the recipe just uses the [`topoplot`](@ref) defaults and passes through the attributes.

!!! note
    The 10-05 channel locations are "perfect" spherical locations based on https://github.com/sappelhoff/eeg_positions/ - the mne-default 10-20 locations are _not_, they were warped to a fsaverage head. Which makes the locations provided here good for visualizations, but not good for source localisation.

!!! note
    You MUST set `label_text=true` for labels to display.
"""
eeg_topoplot

@deprecate eeg_topoplot(data::AbstractVector{<:Real}, labels::Vector{<:AbstractString}) eeg_topoplot(data; labels)
@deprecate eeg_topoplot!(fig, data::AbstractVector{<:Real}, labels::Vector{<:AbstractString}) eeg_topoplot!(fig, data; labels)

function draw_ear_nose!(parent, circle; kw...)
    # draw circle
    head_points = lift(circle) do circle
        points = decompose(Point2f, circle)
        diameter = 2GeometryBasics.radius(circle)
        middle = GeometryBasics.origin(circle)
        nose = (Point2f[(-0.05, 0.5), (0.0, 0.55), (0.05, 0.5)] .* diameter) .+ (middle,)
        push!(points, Point2f(NaN))
        append!(points, nose)
        ear = (Point2f[
            (0.497, 0.0555), (0.51, 0.0775), (0.518, 0.0783),
            (0.5299, 0.0746), (0.5419, 0.0555), (0.54, -0.0055),
            (0.547, -0.0932), (0.532, -0.1313), (0.51, -0.1384),
            (0.489, -0.1199)] .* diameter)

        push!(points, Point2f(NaN))
        append!(points, ear .+ middle)
        push!(points, Point2f(NaN))
        append!(points, (ear .* Point2f(-1, 1)) .+ (middle,))
        return points
    end

    lines!(parent, head_points; kw...)

end


const CHANNELS_10_05 = ["af1","af10","af10h","af1h","af2","af2h","af3","af3h",
                        "af4","af4h","af5","af5h","af6","af6h","af7","af7h","af8",
                        "af8h","af9","af9h","aff1","aff10","aff10h","aff1h","aff2",
                        "aff2h","aff3","aff3h","aff4","aff4h","aff5","aff5h","aff6",
                        "aff6h","aff7","aff7h","aff8","aff8h","aff9","aff9h","affz",
                        "afp1","afp10","afp10h","afp1h","afp2","afp2h","afp3","afp3h",
                        "afp4","afp4h","afp5","afp5h","afp6","afp6h","afp7","afp7h",
                        "afp8","afp8h","afp9","afp9h","afpz","afz","c1","c1h","c2",
                        "c2h","c3","c3h","c4","c4h","c5","c5h","c6","c6h","ccp1",
                        "ccp1h","ccp2","ccp2h","ccp3","ccp3h","ccp4","ccp4h","ccp5",
                        "ccp5h","ccp6","ccp6h","ccpz","cp1","cp1h","cp2","cp2h","cp3",
                        "cp3h","cp4","cp4h","cp5","cp5h","cp6","cp6h","cpp1","cpp1h",
                        "cpp2","cpp2h","cpp3","cpp3h","cpp4","cpp4h","cpp5","cpp5h",
                        "cpp6","cpp6h","cppz","cpz","cz","f1","f10","f10h","f1h",
                        "f2","f2h","f3","f3h","f4","f4h","f5","f5h","f6","f6h",
                        "f7","f7h","f8","f8h","f9","f9h","fc1","fc1h","fc2","fc2h",
                        "fc3","fc3h","fc4","fc4h","fc5","fc5h","fc6","fc6h","fcc1",
                        "fcc1h","fcc2","fcc2h","fcc3","fcc3h","fcc4","fcc4h","fcc5",
                        "fcc5h","fcc6","fcc6h","fccz","fcz","ffc1","ffc1h","ffc2",
                        "ffc2h","ffc3","ffc3h","ffc4","ffc4h","ffc5","ffc5h","ffc6",
                        "ffc6h","ffcz","fft10","fft10h","fft7","fft7h","fft8","fft8h",
                        "fft9","fft9h","ft10","ft10h","ft7","ft7h","ft8","ft8h","ft9",
                        "ft9h","ftt10","ftt10h","ftt7","ftt7h","ftt8","ftt8h","ftt9",
                        "ftt9h","fp1","fp1h","fp2","fp2h","fpz","fz","i1","i1h","i2",
                        "i2h","iz","lpa","n1","n1h","n2","n2h","nas","nfp1","nfp1h",
                        "nfp2","nfp2h","nfpz","nz","o1","o1h","o2","o2h","oi1","oi1h",
                        "oi2","oi2h","oiz","oz","p1","p10","p10h","p1h","p2","p2h",
                        "p3","p3h","p4","p4h","p5","p5h","p6","p6h","p7","p7h","p8",
                        "p8h","p9","p9h","po1","po10","po10h","po1h","po2","po2h",
                        "po3","po3h","po4","po4h","po5","po5h","po6","po6h","po7",
                        "po7h","po8","po8h","po9","po9h","poo1","poo10","poo10h",
                        "poo1h","poo2","poo2h","poo3","poo3h","poo4","poo4h","poo5",
                        "poo5h","poo6","poo6h","poo7","poo7h","poo8","poo8h","poo9",
                        "poo9h","pooz","poz","ppo1","ppo10","ppo10h","ppo1h","ppo2",
                        "ppo2h","ppo3","ppo3h","ppo4","ppo4h","ppo5","ppo5h","ppo6",
                        "ppo6h","ppo7","ppo7h","ppo8","ppo8h","ppo9","ppo9h","ppoz",
                        "pz","rpa","t10","t10h","t7","t7h","t8","t8h","t9","t9h",
                        "tp10","tp10h","tp7","tp7h","tp8","tp8h","tp9","tp9h","tpp10",
                        "tpp10h","tpp7","tpp7h","tpp8","tpp8h","tpp9","tpp9h","ttp10",
                        "ttp10h","ttp7","ttp7h","ttp8","ttp8h","ttp9","ttp9h"]

const CHANNEL_TO_POSITION_10_05 = begin
 # We load this during precompilation, so that this gets stored as a global
    # that's immediately loaded when loading the package
    result = Matrix{Float64}(undef, 348, 2)
    read!(assetpath("layout_10_05.bin"), result)
    positions = Point2f.(result[:, 1], result[:, 2])
    d = Dict{String,Point2f}(zip(CHANNELS_10_05, positions))
    d["t3"] = d["t7"]
    d["t4"] = d["t8"]
    d["t5"] = d["p7"]
    d["t6"] = d["p8"]
     d

end

# even though these are not actively used, sometimes they can be helpful just to plot a default subset of channels. Therefore we havent deleted them yet (because 10_05 is a superset)
const CHANNELS_10_20 = ["fp1", "f3", "c3", "p3", "o1", "f7", "t3", "t5", "fz", "cz", "pz", "fp2", "f4", "c4", "p4", "o2", "f8", "t4", "t6"]

#=const CHANNEL_TO_POSITION_10_20 = begin
    # We load this during precompilation, so that this gets stored as a global
    # that's immediately loaded when loading the package
    result = Matrix{Float64}(undef, 19, 2)
    read!(assetpath("layout_10_20.bin"), result)
    positions = Point2f.(result[:, 1], result[:, 2])
    Dict{String,Point2f}(zip(CHANNELS_10_20, positions))
end
=#

"""
    labels2positions(labels)
Currently supports 10/20 and 10/05 layout, by looking it up in `TopoPlots.CHANNEL_TO_POSITION_10_05`.
"""
function labels2positions(labels)
    return map(labels) do label
        key = lowercase(label)
        if haskey(CHANNEL_TO_POSITION_10_05, key)
            return CHANNEL_TO_POSITION_10_05[key]
        else
            error("Currently only 10/05 is supported. Found label: $(label)")
        end
    end
end

#function Makie.convert_arguments(::Type{<:EEG_TopoPlot}, data::AbstractVector{<:Real})
#    return (data, labels2positions(labels))#
    #
#end

function Makie.plot!(plot::EEG_TopoPlot)

    positions = lift(plot.labels, plot.positions) do labels, positions

        if positions isa Makie.Automatic
            (!isnothing(labels) && labels != Makie.Automatic) || error("Either positions or labels (10/05-lookup) have to be specified")

            return labels2positions(labels)
        else
            # apply same conversion as for e.g. the scatter arguments
            return convert_arguments(Makie.PointBased(), positions)[1]
        end
    end
    plot.labels = lift(plot.labels, plot.positions) do labels, positions

        if isnothing(labels) || labels isa Makie.Automatic
                return ["sensor $i" for i in 1:length(positions)]
        else
            return labels
        end
    end
    tplot = topoplot!(plot, Attributes(plot), plot.data, positions;)
    head = plot_or_defaults(to_value(plot.head), Attributes(), :head)
    if !isnothing(head)
        draw_ear_nose!(plot, tplot.geometry; head...)
    end
    return
end
