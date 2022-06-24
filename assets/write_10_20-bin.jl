using PyMNE, PyCall, TopoPlots
channels = ["fp1", "f3", "c3", "p3", "o1", "f7", "t3", "t5", "fz", "cz", "pz", "fp2", "f4", "c4", "p4", "o2", "f8", "t4", "t6"]
info = pycall(PyMNE.mne.create_info, PyObject, channels, 120.0; ch_types="eeg")
info.set_montage("standard_1020"; match_case=false)
layout = PyMNE.mne.find_layout(info)
write(TopoPlots.assetpath("layout_10_20.bin"),  hcat(layout.pos[:, 1], layout.pos[:, 2]))
