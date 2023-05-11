
"""
Helper function converting a matrix (channel x times) to a tidy dataframe
    with columns :erp, :time and :label
"""
function eeg_matrix_to_dataframe(data, label)
    df = DataFrame(data', label)
    df[!, :time] .= 1:nrow(df)
    df = stack(df, Not([:time]); variable_name=:label, value_name="erp")
    return df
end

"""
function eeg_topoplot_series(data::DataFrame,
    Δbin;
    col_y=:erp,
    col_label=:label,
    col=:time,
    row=nothing,
    figure = NamedTuple(),
    combinefun=mean,
    topoplot_attributes...
    )



Plot a series of topoplots. The function automatically takes the `combinefun=mean` over the `:time`` column of `data` in `Δbin` steps.

Dataframe `data` needs columns `:time` and `col_y(=:erp)`, and `col_label(=:label)`.
If `data` is a `Matrix`, it is automatically cast to a dataframe, time-bins are then in samples, labels are `string.(1:size(data,1))`
`
Δbin in `:time`-units, specifise the time-steps.

All other keyword arguments are forwarded to the EEG_TopoPlot (eeg_toplot) recipe. In most cases user should provide the electrode positions via
`positions=pos`.

`col` and `row` specify the field to split by columns and rows. By default `col=:time`, to split by the time field and `row=nothing`. Useful
to split by a condition e.g. `...(...,col=:time, row=:condition)` would result in multiple (as many as different values in df.condition) rows of topoplot series

`figure` allows to include information for the figure generation. Alternatively you can provide a fig object `eeg_topoplot_series!(fig,data::DataFrame,Δbin; kwargs..)`

# Examples
Desc
```julia-repl
julia> df = DataFrame(:erp=>repeat(1:63,100),:time=>repeat(1:20,5*63),:label=>repeat(1:63,100)) # fake data
julia> pos = [(1:63)./63 .* (sin.(range(-2*pi,2*pi,63))) (1:63)./63 .* cos.(range(-2*pi,2*pi,63))].*0.5 .+0.5 # fake electrode positions
julia> pos = [Point2.(pos[k,1],pos[k,2]) for k in 1:size(pos,1)]
julia> eeg_topoplot_series(df,5; positions=pos)
```

"""
function eeg_topoplot_series(data::DataFrame, Δbin; figure=NamedTuple(), kwargs...)
    return eeg_topoplot_series!(Figure(; figure...), data, Δbin; kwargs...)
end
function eeg_topoplot_series(data::AbstractMatrix, Δbin; figure=NamedTuple(), kwargs...)
    return eeg_topoplot_series!(Figure(; figure...), data, Δbin; kwargs...)
end
# allow to specify Δbin as an keyword for nicer readability
eeg_topoplot_series(data::DataFrame; Δbin, kwargs...) = eeg_topoplot_series(data, Δbin; kwargs...)
AbstractMatrix
function eeg_topoplot_series!(fig, data::AbstractMatrix, Δbin; kwargs...)
    return eeg_topoplot_series!(fig, data, string.(1:size(data, 1)), Δbin; kwargs...)
end

# convert a 2D Matrix to the dataframe
function eeg_topoplot_series(data::AbstractMatrix, labels, Δbin; kwargs...)
    return eeg_topoplot_series(eeg_matrix_to_dataframe(data, labels), Δbin; kwargs...)
end
function eeg_topoplot_series!(fig, data::AbstractMatrix, labels, Δbin; kwargs...)
    return eeg_topoplot_series!(fig, eeg_matrix_to_dataframe(data, labels), Δbin; kwargs...)
end

"""
eeg_topoplot_series!(fig,data::DataFrame,Δbin; kwargs..)
In place plotting of topoplot series
see eeg_topoplot_series(data,Δbin) for help
"""
function eeg_topoplot_series!(fig, data::DataFrame,
                              Δbin;
                              col_y=:erp,
                              col_label=:label,
                              col=:time,
                              row=nothing,
                              combinefun=mean,
                              topoplot_attributes...)

    # cannot be made easier right now, but Simon promised a simpler solution "soonish"
    axisOptions = (aspect=1, xgridvisible=false, xminorgridvisible=false, xminorticksvisible=false,
                   xticksvisible=false, xticklabelsvisible=false, xlabelvisible=false, ygridvisible=false,
                   yminorgridvisible=false, yminorticksvisible=false, yticksvisible=false,
                   yticklabelsvisible=false, ylabelvisible=false,
                   leftspinevisible=false, rightspinevisible=false, topspinevisible=false,
                   bottomspinevisible=false, limits=((-0.25, 1.25), (-0.25, 1.25)))

    # aggregate the data over time-bins
    data_mean = df_timebin(data, Δbin;
                           col_y=col_y,
                           fun=combinefun,
                           grouping=[col_label, col, row])

    # using same colormap + contour levels for all plots
    (q_min, q_max) = Statistics.quantile(data_mean[:, col_y], [0.001, 0.999])
    # make them symmetrical
    q_min = q_max = max(abs(q_min), abs(q_max))
    q_min = -q_min

    topoplot_attributes = merge((colorrange=(q_min, q_max), contours=(levels=range(q_min, q_max; length=7),)),
                        topoplot_attributes)

    # do the col/row plot

    select_col = isnothing(col) ? 1 : unique(data_mean[:, col])
    select_row = isnothing(row) ? 1 : unique(data_mean[:, row])

    for r in 1:length(select_row)
        for c in 1:length(select_col)
            ax = Axis(fig[r, c]; axisOptions...)
            # select one topoplot
            sel = 1 .== ones(size(data_mean, 1)) # select all
            if !isnothing(col)
                sel = sel .&& (data_mean[:, col] .== select_col[c]) # subselect
            end
            if !isnothing(row)
                sel = sel .&& (data_mean[:, row] .== select_row[r]) # subselect
            end
            df_single = data_mean[sel, :]
            # select labels
            labels = df_single[:, col_label]
            # select data
            d_vec = df_single[:, col_y]
            # plot it
            eeg_topoplot!(ax, d_vec, labels; topoplot_attributes...)
        end
    end
    colgap!(fig.layout, 0)

    return fig
end

"""
function df_timebin(df,Δbin;col_y=:erp,fun=mean,grouping=[])

Split/Combine dataframe according to equally spaced time-bins

- `df` AbstractTable with columns `:time` and `col_y` (default `:erp`), and all columns in `grouping`
- `Δbin` bin-size in `:time`-units

- `col_y` default :erp, the column to combine (using `fun`) over
- `fun` function to combine, default is `mean`
- `grouping` (vector of symbols/strings) default empty vector, columns to group the data by, before aggregating. Values of `nothing` are ignored

"""
function df_timebin(df, Δbin; col_y=:erp, fun=mean, grouping=[])
    tmin = minimum(df.time)
    tmax = maximum(df.time)

    bins = range(; start=tmin, step=Δbin, stop=tmax)
    df = deepcopy(df) # cut seems to change stuff inplace
    df.time = cut(df.time, bins; extend=true)

    grouping = grouping[.!isnothing.(grouping)]

    df_m = combine(groupby(df, unique([:time, grouping...])), col_y => fun)
    #df_m = combine(groupby(df,Not(y)),y=>fun)
    rename!(df_m, names(df_m)[end] => col_y) # remove the _fun part of the new column
    return df_m
end
