ELECTRODE_POSITIONS = let
    electrodes = [
        "Fp1" => ( -92,-72),
        "AF3" => ( -74,-65),
        "F7" => ( -92,-36),
        "F3" => ( -60,-51),
        "FC1" => ( -32,-45),
        "FC5" => ( -72,-21),
        "T7" => ( -92,  0),
        "C3" => ( -46,  0),
        "CP1" => ( -32, 45),
        "CP5" => ( -72, 21),
        "P7" => ( -92, 36),
        "P3" => ( -60, 51),
        "Pz" => (  46,-90),
        "PO3" => ( -74, 65),
        "O1" => ( -92, 72),
        "Oz" => (  92,-90),
        "O2" => (  92,-72),
        "PO4" => (  74,-65),
        "P4" => (  60,-51),
        "P8" => (  92,-36),
        "CP6" => (  72,-21),
        "CP2" => (  32,-45),
        "C4" => (  46,  0),
        "T8" => (  92,  0),
        "FC6" => (  72, 21),
        "FC2" => (  32, 45),
        "F4" => (  60, 51),
        "F8" => (  92, 36),
        "AF4" => (  74, 65),
        "Fp2" => (  92, 72),
        "Fz" => (  46, 90),
        "Cz" => (   0,  0),
        "Nz" => ( 115, 90),
        "LPA" => (-115,  0),
        "RPA" => ( 115,  0),
    ]

    theta = deg2rad.(first.(last.(electrodes)))
    phi = deg2rad.(last.(last.(electrodes)))

    positions = Point2f.(phi .* cos.(theta), phi .* sin.(theta))

    Dict(Pair.(lowercase.(first.(electrodes)), positions))
end
