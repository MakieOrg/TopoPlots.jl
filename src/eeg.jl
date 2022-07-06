
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






"""
Helper function converting a matrix (channel x times) to a tidy dataframe
    with columns :erp, :time and :label
"""
function eeg_matrixToDataframe(data,label)
    df = DataFrame(data',label)
    df[!,:time] .= 1:nrow(df)
    df = stack(df,Not([:time]),variable_name=:label,value_name="erp")
    return df
end



"""
function eeg_topoplot_series(data::DataFrame,
    Δbin; 				 
    col_y=:erp,
    col_label=:label,
    topoplotCfg=NamedTuple(),
    mappingCfg=(col=:time,),
    figureCfg = NamedTuple(),
    combinefun=mean
    )



Plot a series of topoplots. The function automatically takes the `combinefun=mean` over the `:time`` column of `data` in `Δbin` steps.

Dataframe `data` needs columns `:time` and `col_y(=:erp)`, and `col_label(=:label)`.
If `data` is a `Matrix`, it is automatically cast to a dataframe, time-bins are then in samples
`
Δbin in `:time`-units, specifise the time-steps. 

Further specifications via topoplotCfg for the EEG_TopoPlot recipe. In most cases user should provide the electrode positions via
`topoplotCFG = (positions=pos,)` # note the trailling comma to make it a NamedTuple

`mappingCfg` is for the mapping command of AOG, typical usages would be `mappingCfg=(col=:time,row=:condition,)` to layout the plot. Other topoplot modifications are possible, as `topoplotCfg`` as it put to AoG.visual
in pseudo-code:
AoG.data(data) * mapping(col_y,col_label,mappingCfg...)*visual(EEG_TopoPlot,topoplotCfg...)
 
`figureCfg` allows to include information for the figure generation. Alternatively you can provide a fig object `eeg_topoplot_series!(fig,data::DataFrame,Δbin; kwargs..)`

# Examples
Desc
```julia-repl
julia> df = DataFrame(:erp=>repeat(1:63,100),:time=>repeat(1:20,5*63),:label=>repeat(1:63,100)) # fake data
julia> pos = [(1:63)./63 .* (sin.(range(-2*pi,2*pi,63))) (1:63)./63 .* cos.(range(-2*pi,2*pi,63))].*0.5 .+0.5 # fake electrode positions
julia> pos = [Point2.(pos[k,1],pos[k,2]) for k in 1:size(pos,1)]
julia> eeg_topoplot_series(df,5;topoplotCfg=(positions=pos,))
```

"""
eeg_topoplot_series(data::DataFrame,Δbin;figureCfg = NamedTuple(),kwargs...) = eeg_topoplot_series!(Figure(; figureCfg...),data,Δbin;kwargs...)
eeg_topoplot_series(data::Matrix,Δbin;figureCfg = NamedTuple(),kwargs...) = eeg_topoplot_series!(Figure(; figureCfg...),data,Δbin;kwargs...)
# allow to specify Δbin as an keyword for nicer readability
eeg_topoplot_series(data::DataFrame;Δbin,kwargs...) = eeg_topoplot_series(data,Δbin;kwargs...)
# if no labels are provided, just 1:nchannel
eeg_topoplot_series(data::Matrix,Δbin;kwargs...) = eeg_topoplot_series(data,string.(1:size(data,1)),Δbin;kwargs...)
eeg_topoplot_series!(fig,data::Matrix,Δbin;kwargs...) = eeg_topoplot_series!(fig,data,string.(1:size(data,1)),Δbin;kwargs...)

# convert a 2D Matrix to the dataframe
eeg_topoplot_series(     data::Matrix,labels,Δbin;kwargs...) = eeg_topoplot_series(eeg_matrixToDataframe(data,labels),Δbin;kwargs...)
eeg_topoplot_series!(fig,data::Matrix,labels,Δbin;kwargs...) = eeg_topoplot_series!(fig,eeg_matrixToDataframe(data,labels),Δbin;kwargs...)



"""
eeg_topoplot_series!(fig,data::DataFrame,Δbin; kwargs..)
In place plotting of topoplot series
see eeg_topoplot_series(data,Δbin) for help
""" 
function eeg_topoplot_series!(fig,data::DataFrame,
                            Δbin; 				 
                            col_y=:erp,
                            col_label=:label,
                            topoplotCfg=NamedTuple(),
                            mappingCfg=(col=:time,),
                            combinefun=mean
                            )


    # cannot be made easier right now, but Simon promised a simpler solution "soonish"
    axisOptions = (aspect = 1,xgridvisible=false,xminorgridvisible=false,xminorticksvisible=false,xticksvisible=false,xticklabelsvisible=false,xlabelvisible=false,ygridvisible=false,yminorgridvisible=false,yminorticksvisible=false,yticksvisible=false,yticklabelsvisible=false,ylabelvisible=false,
    leftspinevisible = false,rightspinevisible = false,topspinevisible = false,bottomspinevisible=false,limits=((-.25,1.25),(-.25,1.25)),)

    # aggregate the data over time-bins
    data_mean = df_timebin(data,Δbin;
            col_y=col_y,
            fun=combinefun,
            grouping=[col_label,values(mappingCfg)...]
            )

    
    # do the AoG plot
    aogFig =  AlgebraOfGraphics.data(data_mean)*
        mapping(col_y,col_label;mappingCfg...)*
        visual(EEG_TopoPlot;topoplotCfg...)|>
            x->draw!(fig,x,axis=axisOptions,facet=(linkxaxes = :none,linkyaxes = :none,))
    colgap!(fig.layout,0)
    fig

end


"""
function df_timebin(df,Δbin;col_y=:erp,fun=mean,grouping=[])

Split/Combine dataframe according to equally spaced time-bins

- `df` AbstractTable with columns `:time` and `col_y` (default `:erp`), and all columns in `grouping`
- `Δbin` bin-size in `:time`-units

- `col_y` default :erp, the column to combine (using `fun`) over
- `fun` function to combine, default is `mean`
- `grouping` (vector of symbols/strings) default empty vector, columns to group the data by, before aggregating

"""
function df_timebin(df,Δbin;col_y=:erp,fun=mean,grouping=[])
    tmin = minimum(df.time)
    tmax = maximum(df.time)
    
    bins = range(start=tmin,step=Δbin,stop=tmax)
    df = deepcopy(df) # cut seems to change stuff inplace
    df.time = cut(df.time,bins,extend=true)
    
    df_m = combine(groupby(df,unique([:time, grouping...])),col_y=>fun)
    #df_m = combine(groupby(df,Not(y)),y=>fun)
    rename!(df_m,names(df_m)[end]=>col_y) # remove the _fun part of the new column
    return df_m

end;

