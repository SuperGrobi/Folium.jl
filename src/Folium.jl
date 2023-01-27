module Folium
using PyCall
using GeoInterface

const flm = PyNULL()

function __init__()
    # weird stuff with importing at runtime. Might switch to pyimport_conda("folium", "folium")
    copy!(flm, pyimport_conda("folium", "folium", "conda-forge"))
    nothing
end

##############################################
## FOLIUM TAKES ALL COORDINATES AS LAT, LON ##
##############################################
struct FoliumMap
    obj::PyObject
    max_width::String
end

function FoliumMap(; kwargs...)
    kw = Dict(kwargs)
    max_width = get(kw, :max_width, "1300px")
    if !haskey(kwargs, :location)
        # this might be very useless...‚
        flmmap = flm.Map(; location=[0.0, 0.0], tiles="CartoDB PositronNoLabels", kw...)
    else
        flmmap = flm.Map(; tiles="CartoDB PositronNoLabels", kw...)
    end
    return FoliumMap(flmmap, string(max_width))
end

function splice_width(flmmap::FoliumMap)
    mapstring = repr("text/html", flmmap.obj)
    m = match(r"(100%)", mapstring)
    ms = mapstring[1:m.offset-1] * "100%; max-width:$(flmmap.max_width)" * mapstring[m.offset+4:end]
    return ms
end

# for nice plot in VS Codes
function Base.show(io::IO, ::MIME"juliavscode/html", flmmap::FoliumMap)
    Base.show(io, "text/html", flmmap)
end

# for nice plots everywhere else
function Base.show(io::IO, mime::MIME"text/html", flmmap::FoliumMap)
    ms = splice_width(flmmap)
    write(io, ms)
end

# this takes a list like: [(minlat, minlon), (maxlat, maxlon)]
fit_bounds!(flmmap, bounds) = flmmap.obj.fit_bounds(bounds)

export FoliumMap
export draw, draw!, fit_bounds!

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

draw!(fig) = fig

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

function draw(args...; figure_params=Dict(), kwargs...)
    @nospecialize
    fig = FoliumMap(; figure_params...)
    return draw!(fig, args...; kwargs...)
end

include("geoplotting.jl")
end
