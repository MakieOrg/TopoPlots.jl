### A Pluto.jl notebook ###
# v0.19.4

using Markdown
using InteractiveUtils

# ╔═╡ 31cea56f-f6d1-4412-a4b3-14bfe714491e
	begin
	using Pkg
	Pkg.activate(temp=true)
	end

# ╔═╡ f49917ee-d5de-11ec-2e00-315d3bbbf4fc
# ╠═╡ show_logs = false
begin

	Pkg.add(["JLD2","CairoMakie","PyMNE","PyPlot"])
	Pkg.add(url="https://github.com/unfoldtoolbox/UnfoldMakie.jl",rev="topoplot")

	
end

# ╔═╡ dcdd7a47-fd6c-4ec6-ac18-dd8fc07924bf
begin
	using JLD2
	using CairoMakie
	using UnfoldMakie
	using PyMNE
	using PyCall
end

# ╔═╡ 1ba342d1-ee1d-4a32-b750-4901b57c8df6
begin
	pos = load("example.jld2","pos")
	data = load("example.jld2","data")
end;

# ╔═╡ 17e7a862-ac44-4802-9449-a98894657ad0
 begin # convert x/y to mne position
	 info = pycall(PyMNE.io.meas_info.create_info, PyObject,string.(1:size(pos,2)), sfreq=256, ch_types="eeg") # fake info 
    raw = PyMNE.io.RawArray(data[:,:,1], info) # fake raw with fake info
	 chname_pos_dict = Dict(string.(1:size(pos,2)) .=> [pos[:,p] for p in 1:size(pos,2)])
montage = PyMNE.channels.make_dig_montage(ch_pos=chname_pos_dict,coord_frame="head")
    raw.set_montage(montage) # set montage (why??)
	 
	 layout_from_raw = PyMNE.channels.make_eeg_layout(get_info(raw))
	 pos2 = layout_from_raw.pos
 end;

# ╔═╡ a5dc2801-9fa8-4193-9c1e-254bd692c1b7
begin
CairoMakie.scatter(pos[1,:]*0.05 .+1.5,pos[2,:]*0.05.+0.5,color="blue") # no project
CairoMakie.scatter!(pos2[:,1],pos2[:,2],color="red") # projection
current_figure()
end

# ╔═╡ 91da8540-5cda-43b3-8bc1-72d9ede1fcc9
lines(data[1,:,1]) # channel x time x [estimate,std,pvalue]

# ╔═╡ 5edd1570-e6cd-4eeb-ae1b-bcc0d0901e47
begin
	f = CairoMakie.Figure()
	f[1,1] = Axis(f)
plot_topoplot(f[1,1],data[:,end,1],pos2[:,1:2])
	f
end

# ╔═╡ c29e489b-bc21-4f17-b676-a26c3788cad1
PyMNE.viz.plot_topomap(data[:,end,1],pos2)

# ╔═╡ Cell order:
# ╠═31cea56f-f6d1-4412-a4b3-14bfe714491e
# ╠═f49917ee-d5de-11ec-2e00-315d3bbbf4fc
# ╠═dcdd7a47-fd6c-4ec6-ac18-dd8fc07924bf
# ╠═1ba342d1-ee1d-4a32-b750-4901b57c8df6
# ╠═a5dc2801-9fa8-4193-9c1e-254bd692c1b7
# ╠═17e7a862-ac44-4802-9449-a98894657ad0
# ╠═91da8540-5cda-43b3-8bc1-72d9ede1fcc9
# ╠═5edd1570-e6cd-4eeb-ae1b-bcc0d0901e47
# ╠═c29e489b-bc21-4f17-b676-a26c3788cad1
