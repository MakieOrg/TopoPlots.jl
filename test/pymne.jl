using CairoMakie
using Dates
using DSP
using ERPs
using Onda
using PyPlot
using StableRNGs
using TimeSpans
using PyCall
using PyMNE

function sinusoid(sample_rate::Int, n_samples::Int, n_chan::Int; frequency=1, phase=0,
                  amplitude=1)
    data = ones(Float64, (n_chan, n_samples))
    for col in 1:size(data, 2)
        data[:, col] .= col
    end
    @. data = sin(2π * frequency * data / sample_rate + phase) * amplitude
    return data
end

ROOT = mktempdir()

# a template Trials to play around with:
function make_some_trials(; seed=1, n_trials=10, sample_rate=1024, channels=["fp1", "f3", "c3", "p3", "o1", "f7", "t3", "t5", "fz", "cz", "pz", "fp2", "f4", "c4", "p4", "o2", "f8", "t4", "t6"],
                          frequency=1, phase=0, amplitude=0, amplitude_noise=1,
                          phase_noise=0,
                          window=TimeSpan(Millisecond(0), Millisecond(1000)))
    rng = StableRNG(seed)

    n_samples = index_from_time(sample_rate, duration(window))
    n_chan = length(channels)
    # trials data is a trial × channel × time tensor
    data = amplitude_noise * rand(rng, Float32, n_trials, n_chan, n_samples)

    for idx in 1:size(data, 1)
        data[idx, :, :] = rand(size(data, 2), size(data, 3))
    end

    return Trials(sample_rate, channels, window, data, Dict{Symbol,Any}())
end


deviants = make_some_trials(; n_trials=1, amplitude=10, amplitude_noise=0, phase_noise=0.5)
standards = make_some_trials(; n_trials=10, amplitude=3, amplitude_noise=0, phase_noise=0.5)

epochs = set_montage!(to_epochs_array(deviants), "standard_1020")
# not really interesting because we only have 3 electrodes
p = topoplot(epochs)


begin
    info = pycall(PyMNE.mne.create_info, PyObject, deviants.channels, deviants.sample_rate; ch_types="eeg")
    info.set_montage("standard_1020"; match_case=false, raise_if_subset=false)
    layout = PyMNE.mne.find_layout(info)
    X = layout.pos[:, 1]
    Y = layout.pos[:, 2]
    positions = Point2f.(X, Y)
    X, Y = first.(positions), last.(positions)
    data = deviants.data[1, :, 1]

    xg, yg = generate_topoplot_xy(X, Y)

    v = spline2d_mne(Y, X, yg, xg, data; s=10^6)
    cmap = cgrad(:RdBu, rev = true)
    crange = (-maximum(data), maximum(data))
    fig, ax, pl = heatmap(xg, yg, v, interpolate=true, axis=(aspect=DataAspect(),), colormap=cmap, colorrange=crange)
    scatter!(ax, X, Y, markersize=10, color=data, strokewidth=1, strokecolor=:white, colormap=cmap, colorrange=crange) # add electrodes
    fig
end
