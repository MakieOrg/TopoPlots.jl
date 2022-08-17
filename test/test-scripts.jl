using TopoPlots, PyCall, PyPlot, PyMNE

data, positions = TopoPlots.example_data()
pos = vcat(first.(positions)', last.(positions)')

info = pycall(PyMNE.mne.create_info, PyObject, TopoPlots.CHANNELS_10_20, 120; ch_types="eeg")
info.set_montage("standard_1020"; match_case=false)
layout = PyMNE.mne.find_layout(info)

X = layout.pos[:, 1]
Y = layout.pos[:, 2]

PyMNE.viz.plot_topomap(rand(19), layout.pos) |> display

gcf()

using TopoPlots, PyCall, PyPlot, PyMNE

data, positions = TopoPlots.example_data()
pos = hcat(first.(positions), last.(positions))
info = pycall(PyMNE.io.meas_info.create_info, PyObject, string.(1:size(pos,2)), sfreq=256, ch_types="eeg") # fake info
raw = PyMNE.io.RawArray(data[:,:,1], info) # fake raw with fake info
chname_pos_dict = Dict(string.(1:size(pos,2)) .=> [pos[:, p] for p in 1:size(pos,2)])
montage = PyMNE.channels.make_dig_montage(ch_pos=chname_pos_dict,coord_frame="head")
# raw.set_montage(montage) # set montage (why??)

PyMNE.viz.plot_topomap(data[:,340,1], get_info(raw), names=string.(1:size(pos,2)), show_names=true, vmin=-0.7, vmax=0.7)

positions = TopoPlots.labels2positions(TopoPlots.CHANNELS_10_20)
pos = hcat(first.(positions), last.(positions))
PyMNE.viz.plot_topomap(rand(19), pos)



using TopoPlots, CairoMakie
begin
    # 4 coordinates with one peak
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
    i = 1
    peak_xy = positions[i]
    data = zeros(length(positions))
    data[i] = 1
    fig = topoplot(data, positions; label_scatter=true)
    display(fig)
end

using PyMNE, GeometryBasics

data = rand(10)
begin
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
    posmat = hcat(first.(positions), last.(positions))
    data = zeros(length(positions))
    data[1] = 1.0
    f = PyPlot.figure()
    PyMNE.viz.plot_topomap(data, posmat, sphere=1.1, extrapolate="head", cmap="RdBu_r")
    f
end

begin
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)]
    posmat = hcat(first.(positions), last.(positions))
    data = zeros(length(positions))
    data[1] = 1.0
    fig = eeg_topoplot(data, nothing; positions=positions, label_scatter=(markersize=20,), axis=(aspect=DataAspect(),))
end

begin
    positions = Point2f[(-1, 0), (0, -1), (1, 0), (0, 1), (0, 0)] .* 0.8
    data = zeros(length(positions))
    data[1] = 1.0
    data = rand(length(positions))
    pos, data = TopoPlots.get_bounded(Rect(-1, -1, 2, 2), positions, data, 0.0)

    CairoMakie.scatter(pos, color=data)
end
Rect(Circle(Point2f(0), 1.0))
middle(rect)
begin

    positions = rand(Point2f, 10)
    data = rand(10)
    rect = Rect(positions)
    pos_extra, rect_extended, data_extra = TopoPlots.extrapolate_data(rect, positions, data)
    f, ax, p = Makie.scatter(pos_extra, color=data_extra, markersize=10, axis=(aspect=DataAspect(),))
    scatter!(ax, positions)
    lines!(ax, rect)
    lines!(ax, rect_extended, color=:red)
    f
end
