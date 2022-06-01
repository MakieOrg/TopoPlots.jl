
function spline2d_mne(positions, data; pad=0.01, xres=512, yres=xres)
    rect = Rect2f(positions)
    minpoint = minimum(rect)
    maxpoint = maximum(rect)
    width = widths(rect)
    middle = minpoint .+ (width ./ 2)
    radius = maximum(width ./ 2) .+ 0.1
    @show middle radius
    interp = PyMNE.viz.topomap._GridData([first.(positions) last.(positions)], "head", [middle...], [radius, radius], "mean")
    interp.set_values(data)
    pad_amount = maximum(width) .* pad
    xmin, ymin = minpoint
    xmax, ymax = maxpoint
    xg = LinRange(xmin - pad_amount, xmax + pad_amount, xres)
    yg = LinRange(xmin - pad_amount, xmax + pad_amount, yres)
    # the xg' * ones is a shorthand for np.meshgrid
    return xg, yg, interp.set_locations(xg' .* ones(length(yg)), ones(length(xg))' .* yg)()'
end
