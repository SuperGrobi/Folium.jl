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

function get_layer_class(series_type)
    if series_type === :circle
        return flm.Circle
    elseif series_type === :marker
        return flm.CircleMarker
    elseif series_type === :line
        return flm.PolyLine
    elseif series_type === :polygon
        return flm.Polygon
    else
        throw(ArgumentError("the series type $series_type is not supported. Available types are: [:circle, :marker, :line, :polygon]"))
    end
end

function draw!(fig::FoliumMap, geometry; kwargs...)
    try
        for geo in geometry
            @assert isgeometry(geo) "GeoInterface says that $geo is not a geometry."
            _draw!(fig, geomtrait(geo), geo; kwargs...)
        end
    catch e
        if e isa MethodError
            @assert isgeometry(geometry) "GeoInterface says that $geometry is not a geometry."
            _draw!(fig, geomtrait(geometry), geometry; kwargs...)
        else
            rethrow(e)
        end
    end
    return fig
end

function draw(geometry; figure_params=Dict(), kwargs...)
    fig = FoliumMap(; figure_params...)
    return draw!(fig, geometry; kwargs...)
end


function draw!(fig::FoliumMap, lon, lat, series_type::Symbol; kwargs...)
    layer_class = get_layer_class(series_type)
    fill = false
    fill_opacity = 0.2
    if series_type == :polygon
        # sensible defaults...?
        fill = get(kwargs, :fill, true)
        fill_opacity = get(kwargs, :fill_opacity, 1.0)
    end
    layer_class(collect(zip(lat, lon)); kwargs..., fill=fill, fill_opacity=fill_opacity).add_to(fig.obj)
    return fig
end

function draw(lon, lat, series_type::Symbol; figure_params=Dict(), kwargs...)
    fig = FoliumMap(; figure_params...)
    return draw!(fig, lon, lat, series_type; kwargs...)
end

include("geoplotting.jl")
end
