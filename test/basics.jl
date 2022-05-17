using PyMNE, GeometryBasics, Makie, CairoMakie
using GeometryBasics: Circle, decompose

function spline2d_mne(X, Y, xg, yg, data; kwargs...)

    xmin, xmax = extrema(X)
    ymin, ymax = extrema(Y)
    x_half_w = (xmax - xmin) / 2
    y_half_w = (ymax - ymin) / 2
    xcenter = xmin + x_half_w
    ycenter = ymin + y_half_w

    interp = PyMNE.viz.topomap._GridData([X Y], "head", [xcenter, ycenter, x_half_w + 0.1, y_half_w + 0.1], "mean")
    interp.set_values(to_value(data))
    # the xg' * ones is a shorthand for np.meshgrid
    return interp.set_locations(xg' .* ones(length(yg)), ones(length(xg))' .* yg)()
end

function generate_topoplot_xy(X, Y)
    # get extrema and extend
    # this is for the axis view, i.e. whitespace left/right

    # generate and evaluate a grid
    xg = range(-0.2, stop=1.2, length=512)
    yg = range(-0.2, stop=1.2, length=512)

    # s = smoothing parameter, kx/ky = spline order; for some reason s has to be increadible large...
    return xg, yg
end

begin
    positions = montage_positions
    X, Y = first.(positions), last.(positions)
    data = deviants.data[1, :, 1]

    xg, yg = generate_topoplot_xy(X, Y)

    v = spline2d_mne(Y, X, yg, xg, data; s=10^6)
    fig, ax, pl = heatmap(xg, yg, v, interpolate=true, axis=(aspect=DataAspect(),))
    scatter!(ax, X, Y, markersize=10, color=data, strokewidth=1, strokecolor=:white) # add electrodes
    fig
end
