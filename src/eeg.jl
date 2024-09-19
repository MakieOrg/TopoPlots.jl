
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
* `labels::Vector{<: String} = Makie.automatic`: Add custom labels, in case `label_text` is set to true. If `positions` is not specified, `labels` are used to look up the 10/05 coordinates. See also hint below.
* `head = (color=:black, linewidth=3)`: draw the outline of the head. Set to nothing to not draw the head outline, otherwise set to a namedtuple that get passed down to the `line!` call that draws the shape.
# Some attributes from topoplot are set to different defaults:
* `label_scatter = true`
* `contours = true`
* `enlarge = 1``

Otherwise the recipe just uses the [`topoplot`](@ref) defaults and passes through the attributes.

Hint: The 10-05 channel locations are "perfect" spherical locations based on https://github.com/sappelhoff/eeg_positions/ - the mne-default 10-20 locations are _not_, they were warped to a fsaverage head. Which makes the locations provided here good for visualizations, but not good for source localisation.
"""
eeg_topoplot
 function eeg_topoplot(data,labels;kwargs...) 
    @warn "labels as positional arguments have been deprecated. Please provide them as keyword arguments"
    eeg_topoplot(data;labels=labels,kwargs...)
 end
 function eeg_topoplot!(fig, data,labels;kwargs...) 
    @warn "labels as positional arguments have been deprecated. Please provide them as keyword arguments"
    eeg_topoplot!(fig,data;labels=labels,kwargs...)
 end
 
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


const CHANNELS_10_05 = lowercase.(["AF1","AF10","AF10h","AF1h","AF2","AF2h","AF3","AF3h","AF4","AF4h","AF5","AF5h","AF6","AF6h","AF7","AF7h","AF8","AF8h","AF9","AF9h","AFF1","AFF10","AFF10h","AFF1h","AFF2","AFF2h","AFF3","AFF3h","AFF4","AFF4h","AFF5","AFF5h","AFF6","AFF6h","AFF7","AFF7h","AFF8","AFF8h","AFF9","AFF9h","AFFz","AFp1","AFp10","AFp10h","AFp1h","AFp2","AFp2h","AFp3","AFp3h","AFp4","AFp4h","AFp5","AFp5h","AFp6","AFp6h","AFp7","AFp7h","AFp8","AFp8h","AFp9","AFp9h","AFpz","AFz","C1","C1h","C2","C2h","C3","C3h","C4","C4h","C5","C5h","C6","C6h","CCP1","CCP1h","CCP2","CCP2h","CCP3","CCP3h","CCP4","CCP4h","CCP5","CCP5h","CCP6","CCP6h","CCPz","CP1","CP1h","CP2","CP2h","CP3","CP3h","CP4","CP4h","CP5","CP5h","CP6","CP6h","CPP1","CPP1h","CPP2","CPP2h","CPP3","CPP3h","CPP4","CPP4h","CPP5","CPP5h","CPP6","CPP6h","CPPz","CPz","Cz","F1","F10","F10h","F1h","F2","F2h","F3","F3h","F4","F4h","F5","F5h","F6","F6h","F7","F7h","F8","F8h","F9","F9h","FC1","FC1h","FC2","FC2h","FC3","FC3h","FC4","FC4h","FC5","FC5h","FC6","FC6h","FCC1","FCC1h","FCC2","FCC2h","FCC3","FCC3h","FCC4","FCC4h","FCC5","FCC5h","FCC6","FCC6h","FCCz","FCz","FFC1","FFC1h","FFC2","FFC2h","FFC3","FFC3h","FFC4","FFC4h","FFC5","FFC5h","FFC6","FFC6h","FFCz","FFT10","FFT10h","FFT7","FFT7h","FFT8","FFT8h","FFT9","FFT9h","FT10","FT10h","FT7","FT7h","FT8","FT8h","FT9","FT9h","FTT10","FTT10h","FTT7","FTT7h","FTT8","FTT8h","FTT9","FTT9h","Fp1","Fp1h","Fp2","Fp2h","Fpz","Fz","I1","I1h","I2","I2h","Iz","LPA","N1","N1h","N2","N2h","NAS","NFp1","NFp1h","NFp2","NFp2h","NFpz","Nz","O1","O1h","O2","O2h","OI1","OI1h","OI2","OI2h","OIz","Oz","P1","P10","P10h","P1h","P2","P2h","P3","P3h","P4","P4h","P5","P5h","P6","P6h","P7","P7h","P8","P8h","P9","P9h","PO1","PO10","PO10h","PO1h","PO2","PO2h","PO3","PO3h","PO4","PO4h","PO5","PO5h","PO6","PO6h","PO7","PO7h","PO8","PO8h","PO9","PO9h","POO1","POO10","POO10h","POO1h","POO2","POO2h","POO3","POO3h","POO4","POO4h","POO5","POO5h","POO6","POO6h","POO7","POO7h","POO8","POO8h","POO9","POO9h","POOz","POz","PPO1","PPO10","PPO10h","PPO1h","PPO2","PPO2h","PPO3","PPO3h","PPO4","PPO4h","PPO5","PPO5h","PPO6","PPO6h","PPO7","PPO7h","PPO8","PPO8h","PPO9","PPO9h","PPOz","Pz","RPA","T10","T10h","T7","T7h","T8","T8h","T9","T9h","TP10","TP10h","TP7","TP7h","TP8","TP8h","TP9","TP9h","TPP10","TPP10h","TPP7","TPP7h","TPP8","TPP8h","TPP9","TPP9h","TTP10","TTP10h","TTP7","TTP7h","TTP8","TTP8h","TTP9","TTP9h"])

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

end

# even though these are not actively used, sometimes they can be helpful just to plot a default subset of channels. Therefore we havent deleted them yet (because 10_05 is a superset)
const CHANNELS_10_20 = ["fp1", "f3", "c3", "p3", "o1", "f7", "t3", "t5", "fz", "cz", "pz", "fp2", "f4", "c4", "p4", "o2", "f8", "t4", "t6"]

const CHANNEL_TO_POSITION_10_20 = begin
    # We load this during precompilation, so that this gets stored as a global
    # that's immediately loaded when loading the package
    result = Matrix{Float64}(undef, 19, 2)
    read!(assetpath("layout_10_20.bin"), result)
    positions = Point2f.(result[:, 1], result[:, 2])
    Dict{String,Point2f}(zip(CHANNELS_10_20, positions))
end

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
            error("Currently only 10_05 is supported. Found label: $(label)")
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
            @assert !isnothing(labels) && labels != Makie.Automatic "Either positions or labels (10/20-lookup) have to be specified"
            return labels2positions(labels)
        else
            # apply same conversion as for e.g. the scatter arguments
            return convert_arguments(Makie.PointBased(), positions)[1]
        end
    end
    labels = lift(plot.labels, plot.positions) do labels, positions
        
        if isnothing(labels) || labels isa Makie.Automatic
                return ["sensor $i" for i in 1:length(positions)]
        else
            return labels
        end
    end
    plot.labels = labels
    
    tplot = topoplot!(plot, Attributes(plot), plot.data, positions;)
    head = plot_or_defaults(to_value(plot.head), Attributes(), :head)
    if !isnothing(head)
        draw_ear_nose!(plot, tplot.geometry; head...)
    end
    return
end
