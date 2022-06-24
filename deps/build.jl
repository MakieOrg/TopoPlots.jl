@info "Installing MNE-Python"
using PyCall
pip = pyimport("pip")
flags = split(get(ENV, "PIPFLAGS", ""))
@info "Flags for pip install:" flags
ver = "latest"
@info "MNE version:" ver
packages = ["scipy"]
pip.main(["install"; flags; packages])
