
plot_topoplot(data; kwargs...) = plot_topoplot(Figure(), data; kwargs...)


## define AoG recipe
@recipe(Topoplot, data) do scene
    l_theme = default_theme(scene, Lines)
    Theme(
        positions=defaultLocations(),
        colormap=ColorSchemes.vik,
        sensors=true,
        labels=nothing,
        levels=5,
        interpolation_method=spline2d_mne
        #colorrange=get(l_theme.attributes, :colorrange, automatic),
    )
end

function Makie.plot!(p::Topoplot)
    plot_topoplot(p, p[:data], positions=p[:positions], sensors=p[:sensors], colormap=p[:colormap], interpolation_method=p[:interpolation_method])
    p
end


#--- topoplot series
# plot_topoplot_series
# expects data to contain :time column, groups according to Δbin binsizes, plots topoplot series
# channels have to be in column :channel
plot_topoplot_series(data; Δbin, kwargs...) = plot_topoplot_series(data, Δbin; kwargs...)


"""
 plot_topoplot_series(data::DataFrame,Δbin;y=:estimate,topoplotCfg=NamedTuple(),mappingCfg=(layout=:time,),combinefun=mean)

plot a series of topoplot. The function automatically takes the `combinefun=mean` over the :time column of `data` in `Δbin` steps.

`data` need column :time and :channel, and column `y=:estimate`

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
function plot_topoplot_series(data, Δbin; y=:estimate, topoplotCfg=NamedTuple(), mappingCfg=(layout=:time,), combinefun=mean)

    # cannot be made easier right now, but Simon promised a simpler solution "soonish"
    axisOptions = (aspect=1, xgridvisible=false, xminorgridvisible=false, xminorticksvisible=false, xticksvisible=false, xticklabelsvisible=false, xlabelvisible=false, ygridvisible=false, yminorgridvisible=false, yminorticksvisible=false, yticksvisible=false, yticklabelsvisible=false, ylabelvisible=false,
        leftspinevisible=false, rightspinevisible=false, topspinevisible=false, bottomspinevisible=false,)

    data_mean = topoplot_timebin(data, Δbin; y=y, fun=combinefun)
    #@info data_mean

    AlgebraOfGraphics.data(data_mean) * mapping(y; mappingCfg...) * visual(Topoplot; topoplotCfg...) |> x -> draw(x, axis=axisOptions)

end


function topoplot_timebin(df, Δbin; y=:estimate, fun=mean)
    tmin = minimum(df.time)
    tmax = maximum(df.time)

    bins = range(start=tmin + Δbin / 2, step=Δbin, stop=tmax - Δbin / 2)
    df = deepcopy(df) # cut seems to change stuff inplace
    df.time = cut(df.time, bins, extend=true)

    df_m = combine(groupby(df, [:time, :channel]), y => fun)
    rename!(df_m, names(df_m)[end] => y) # remove the _fun part of the new column
    return df_m

end;

#--- Actual Topoplot Function
function plot_topoplot(h, data; positions=defaultLocations(), levels=5, labels=nothing, s=10^6, sensors=true, colormap=ColorSchemes.vik, interpolation_method=spline2d_mne)
    diameter = 1

    X, Y = position_to_2d(positions)
    xg, yg = generate_topoplot_xy(X, Y)

    v = @lift(rotl90(spline2d_mne(X, Y, xg, yg, $data; s=s)))
    #@info v
    #xg,yg,v = generate_topoplot_grid(X,Y,data;method = spline2d_mne,s=10^6)

    ax = h
    ix = sqrt.([i.^2+j.^2 for i in yg, j in xg]).> (diameter./2)
    # mesh!(ax, Makie.Circle(Point2f(0), diameter/2), color=v, colormap=colormap, shading=false)
    hp = heatmap!(ax, xg, yg, v, interpolate=true, colormap=colormap)
    translate!(hp, 0, 0, -1)
    # contour!(ax, yg, xg, v, linewidth=3, colormap=colormap, levels=levels, overdraw=true)
    # if to_value(sensors)
        draw_sensors(ax, X, Y, data, colormap)
    # end

    # draw_earNose(ax, diameter=diameter)
    # draw_labels(ax, X, Y, labels)

    ax
end

function draw_sensors(ax, X, Y, data, cmap)
    scatter!(ax, X, Y, markersize=10, color=data, colormap=cmap) # add electrodes
end

function draw_labels(ax, X, Y, ::Nothing)
    # in case of empty labels
end

function draw_labels(ax, X, Y, labels)
    #text!(ax, [("$(l)", Point2f0(Y[i],X[i])) for (i,l) in enumerate(labels)]) # add labels
    pos = [(x, y) for (x, y) in zip(X, Y)]

    text!(ax, labels, position=pos, align=(:center, :center))

end
position_to_2d(positions::Observable) = position_to_2d(to_value(positions))
function position_to_2d(positions::Matrix{T}) where {T<:Number}
    # mne layout positions
    return positions[:, 1] .- 0.5, positions[:, 2] .- 0.5
end

# default positions (maybe remove in future?)
function position_to_2d(positions::Vector{T}) where {T}
    # We could try some spherical mapping tool?
    X = first.(first.(positions))
    Y = last.(first.(positions))
    return X, Y
end

function spline2d_dierckx(X, Y, xg, yg, data; s=10^6, kwargs...)
    spl = Spline2D(X, Y, to_value(data), kx=3, ky=3, s=s)

    return evalgrid(spl, yg, xg) # evaluate the spline at the grid locs
end

function spline2d_mne(X, Y, xg, yg, data; kwargs...)
    interp = PyMNE.viz.topomap._GridData([X Y], "head", [0, 0], [1, 1], "mean")
    interp.set_values(to_value(data))
    # the xg' * ones is a shorthand for np.meshgrid
    return interp.set_locations(xg' .* ones(length(yg)), ones(length(xg))' .* yg)()
end

function generate_topoplot_xy(X, Y)

    # get extrema and extend
    # this is for the axis view, i.e. whitespace left/right
    by = 0.4
    xlim = extrema(X) .+ abs.(extrema(X)) .* [-by, by]
    ylim = extrema(Y) .+ abs.(extrema(Y)) .* [-by, by]


    # generate and evaluate a grid
    xg = range(xlim[1], stop=xlim[2], step=0.005)
    yg = range(ylim[1], stop=ylim[2], step=0.005)

    # s = smoothing parameter, kx/ky = spline order; for some reason s has to be increadible large...
    return xg, yg
end



# Would love to use Interpolations.jl, but their 2dsplines only work on a regular grid (as of v0.9)
#interp_cubic = LinearInterpolation((X, Y), data)
#v=interp_cubic.(xg, yg)

function draw_earNose(ax; diameter=0.2)
    # draw nose
    nx = [-0.05, 0.0, 0.05] .* diameter
    ny = [0.5, 0.55, 0.5] .* diameter
    lines!(ax, nx, ny, linewidth=3, color=:black)


    ear_x = [0.497, 0.510, 0.518, 0.5299, 0.5419, 0.54, 0.547, 0.532, 0.510, 0.489] .* diameter
    ear_y = [0.0555, 0.0775, 0.0783, 0.0746, 0.0555, -0.0055, -0.0932, -0.1313, -0.1384, -0.1199] .* diameter
    lines!(ax, ear_x, ear_y, linewidth=3, color=:black) # right
    lines!(ax, -ear_x, ear_y, linewidth=3, color=:black) # left
end



function defaultLocations()
    Fp1	-92	-72
    defaultlocs = """
    1	-18	0.34074074	FP1.
    2	18	0.34074074	FP2.
    3	-39	0.22222222	F3..
    4	39	0.22222222	F4..
    5	-90	0.17037037	C3..
    6	90	0.17037037	C4..
    7	-141	0.22222222	P3..D
    8	141	0.22222222	P4..
    9	-162	0.34074074	O1..
    10	162	0.34074074	O2..
    11	-54	0.34074074	F7..
    12	54	0.34074074	F8..
    13	-90	0.34074074	T3..
    14	90	0.34074074	T4..
    15	-126	0.34074074	T5..
    16	126	0.34074074	T6..
    17	0	0.17037037	FZ..
    18	180	0.17037037	PZ..
    19	-108	0.34074074	T5'.
    20	108	0.34074074	T6'.
    21	-144	0.34074074	O1'.
    22	144	0.34074074	O2'.
    23	-151	0.27407407	P3".
    24	151	0.27407407	P4".
    25	180	0.25555556	PZ".
    26	180	0.34074074	OZ..
    27	180	0.42592593	I...
    28	-162	0.42592593	CB1"
    29	162	0.42592593	CB2"
    30	-144	0.42592593	CB1.
    31	144	0.42592593	CB2.
    """

    positions = map(split(defaultlocs, "\n", keepempty=false)) do line
        pos = split(line, "\t")
        t, r = parse.(Float64, pos[2:3])
        t = deg2rad(t)
        p = Point2f(r * cos(t), r * sin(t))
        n = replace(pos[2], "." => "")
        return (Point2f(-p[2], p[1]), n)
    end
    return positions

end
