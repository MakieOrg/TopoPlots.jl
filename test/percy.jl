image_dir = joinpath(@__DIR__, "test_images")
isdir(image_dir) && rm(image_dir; force=true, recursive=true)
mkdir(image_dir)

"""
Does reference testing with Percy of the figure.
Name needs to be unique across tests for now.
"""
macro test_figure(name, figlike)
    # In julia we can only test if saving the image actually works
    # In percy, we then compare it to the reference images
    return quote
        path = joinpath(image_dir, "$($(name)).png")
        if isfile(path)
            error("Non unique name used for figure: $($(name))")
        end
        save(path, $(esc(figlike)))
        @test true
        $(esc(figlike))
    end
end
