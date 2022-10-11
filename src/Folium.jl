module Folium
using PyCall
using GeoInterface

const flm = PyNULL()

function __init__()
    # weird stuff with importing at runtime. Might switch to pyimport_conda("folium", "folium")
    copy!(flm, pyimport("folium"))
    nothing
end

##############################################
## FOLIUM TAKES ALL COORDINATES AS LAT, LON ##
##############################################
struct FoliumMap
    obj::PyObject
end
function FoliumMap(;kwargs...)
    if !haskey(kwargs, :location)
        # this might be very useless...
        flmmap = flm.Map(;location=[0.0, 0.0], kwargs...)
    else
        flmmap = flm.Map(;kwargs...)
    end
    return FoliumMap(flmmap)
end

# for nice plot in VS Codes
function Base.show(io::IO, ::MIME"juliavscode/html", flmmap::FoliumMap)
    write(io, repr("text/html", flmmap.obj))
end

# for nice plots everywhere else
function Base.show(io::IO, mime::MIME"text/html", flmmap::FoliumMap)
    show(io, mime, flmmap.obj)
end

export FoliumMap
export draw, draw!

function draw!(fig::FoliumMap, geometry; kwargs...)
    @assert isgeometry(geometry) "GeoInterface says that $geometry is not a geometry."
    return _draw!(fig, geomtrait(geometry), geometry; kwargs...)
end

function draw(geometry; figure_params=Dict(), kwargs...)
    fig = FoliumMap(; figure_params...)
    return draw!(fig, geometry; kwargs...)
end

include("geoplotting.jl")
end
