@info "Installing scipy"
using PyCall
run(`$(PyCall.python) -m pip install scipy`)
