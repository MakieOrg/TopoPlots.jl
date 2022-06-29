
@recipe(EEG_TopoPlot, data, labels) do scene
    return Attributes(;
        head = (color=:black, linewidth=3),
        positions = Makie.automatic,
        # overwrite some topoplot defaults
        default_theme(scene, TopoPlot)...,
        label_scatter = true,
        contours = true,
    )
end

"""
    eeg_topoplot(data::Vector{<: Real}, labels::Vector{<: AbstractString})

Attributes:

* `positions::Vector{<: Point} = Makie.automatic`: Can be calculated from label (channel) names. Currently, only 10/20 montage has default coordinates provided.

* `head = (color=:black, linewidth=3)`: draw the outline of the head. Set to nothing to not draw the head outline, otherwise set to a namedtuple that get passed down to the `line!` call that draws the shape.
# Some attributes from topoplot are set to different defaults:
* `label_scatter = true`
* `contours = true`

Otherwise the recipe just uses the [`topoplot`](@ref) defaults and passes through the attributes.
"""
eeg_topoplot

function draw_ear_nose!(parent, circle; kw...)
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

    lines!(parent, head_points; kw...)

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

function Makie.convert_arguments(::Type{<:EEG_TopoPlot}, data::AbstractVector{<: Real})
    return (data, ["sensor $i" for i in 1:length(data)])
end

function Makie.plot!(plot::EEG_TopoPlot)
    positions = lift(plot.labels, plot.positions) do labels, positions
        if positions isa Makie.Automatic
            return labels2positions(labels)
        else
            # apply same conversion as for e.g. the scatter arguments
            return convert_arguments(Makie.PointBased(), positions)[1]
        end
    end

    tplot = topoplot!(plot, Attributes(plot), plot.data, positions; labels=plot.labels)
    head = plot_or_defaults(to_value(plot.head), Attributes(), :head)
    if !isnothing(head)
        draw_ear_nose!(plot, tplot.geometry; head...)
    end
    return
end




# if no labels are provided, just 1:nchannel
plot_topoplot_series(data::Matrix,Δbin;kwargs...) = 
plot_topoplot_series(data,string.(1:size(data,1)),Δbin;kwargs...)

# convert a 2D Matrix to the dataframe
function plot_topoplot_series(data::Matrix,labels,Δbin;kwargs...)

df = DataFrame(data',labels)
df[!,:time] .= 1:nrow(df)
df = stack(df,variable_name=:label,value_name="erp")
plot_topoplot_series(df,Δbin;kwargs...)
end
#--- topoplot series
# plot_topoplot_series
# expects data to contain :time column, groups according to Δbin binsizes, plots topoplot series
# channels have to be in column :channel
plot_topoplot_series(data::DataFrame;Δbin,kwargs...) = plot_topoplot_series(data,Δbin;kwargs...)
"""
(TYPEDSIGNATURES)


plot a series of topoplot. The function automatically takes the `combinefun=mean` over the :time column of `data` in `Δbin` steps.

`data` need column `:time` and `:channel`, and column `y=:estimate`

Further specifications via topoplotCfg for the topoplot recipe (XXX how to do ref?). In most cases user should provide the electrode positions via
`topoplotCFG = (positions=pos,)` # note the trailling comma to make it a tuple

`mappingCfg` is for the mapping command of AOG, typical usages would be `mappingCfg=(col=:time,row=:condition,)` to layout the plot. Topoplot modification via topoplotCfg as it is a visual
 

# Examples
Desc
```julia-repl
julia> data = DataFrame(:estimate=>repeat(1:63,100),:time=>repeat(1:20,5*63),:channel=>repeat(1:63,100)) # fake data
julia> pos = [(1:63)./63 .* (sin.(range(-2*pi,2*pi,63))) (1:63)./63 .* cos.(range(-2*pi,2*pi,63))].*0.5 .+0.5 # fake electrode positions
julia> plot_topoplot_series(data,5;topoplotCfg=(positions=pos,))
```

"""
function plot_topoplot_series(data::DataFrame,Δbin; 				 
    col_y=:erp,
    col_label=:label,
    topoplotCfg=NamedTuple(),
    mappingCfg=(col=:time,),
    combinefun=mean)


    # cannot be made easier right now, but Simon promised a simpler solution "soonish"
    axisOptions = (aspect = 1,xgridvisible=false,xminorgridvisible=false,xminorticksvisible=false,xticksvisible=false,xticklabelsvisible=false,xlabelvisible=false,ygridvisible=false,yminorgridvisible=false,yminorticksvisible=false,yticksvisible=false,yticklabelsvisible=false,ylabelvisible=false,
    leftspinevisible = false,rightspinevisible = false,topspinevisible = false,bottomspinevisible=false,limits=((-.5,1.5),(-.5,1.5)),)

    data_mean = topoplot_timebin(data,Δbin;
            col_y=col_y,
            col_label = col_label,
            fun=combinefun,
            grouping=values(mappingCfg)
            )

    
    return AlgebraOfGraphics.data(data_mean)*
        mapping(col_y,col_label;mappingCfg...)*
        visual(EEG_TopoPlot;topoplotCfg...)|>
            x->draw(x,axis=axisOptions,facet=(linkxaxes = :none,linkyaxes = :none,))

end


"""
(TYPEDSIGNATURES)

Split/Combine dataframe according to equally spaced time-bins

- `df` AbstractTable with fields :time and :channel
- `Δbin` bin-size

- `y` default :estimate, the column to combine (using `fun`) over
- `fun` function to combine, default is `mean`

"""
function topoplot_timebin(df,Δbin;col_y=:erp,col_label=:label,fun=mean,grouping=[])
    tmin = minimum(df.time)
    tmax = maximum(df.time)
    
    bins = range(start=tmin+Δbin/2,step=Δbin,stop=tmax-Δbin/2)
    df = deepcopy(df) # cut seems to change stuff inplace
    df.time = cut(df.time,bins,extend=true)

    df_m = combine(groupby(df,unique([:time,col_label, grouping...])),col_y=>fun)
    #df_m = combine(groupby(df,Not(y)),y=>fun)
    rename!(df_m,names(df_m)[end]=>col_y) # remove the _fun part of the new column
    return df_m

end;