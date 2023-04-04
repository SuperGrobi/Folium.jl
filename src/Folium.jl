module Folium
using PyCall
using GeoInterface
using ColorSchemes
using Colors

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
end

"""

    FoliumMap(; kwargs...)
    
create a new wrapper around the python folium object with kwargs supplied to the figure as well as the map.
"""
function FoliumMap(; kwargs...)
    kw = Dict(kwargs)
    fig_params = Dict(i for i in kwargs if first(i) in [:width, :height, :ratio, :title, :figsize])
    fig = flm.Figure(; fig_params...)
    if haskey(kw, :location)
        kw[:location] = kw[:location] |> reverse
    end
    flmmap = flm.Map(; tiles="CartoDB PositronNoLabels", kw...).add_to(fig)
    return FoliumMap(flmmap)
end

"""

    splice_background(flmmap::FoliumMap)

very hacky way to set the background of the foliummap to white.
"""
function splice_background(flmmap::FoliumMap)
    ms = repr("text/html", flmmap.obj)
    location = findfirst("folium-map&quot; ", ms)[end]
    return ms[1:location] * "style=&quot;background: white;&quot;" * ms[location:end]
end

# for nice plot in VS Codes
function Base.show(io::IO, ::MIME"juliavscode/html", flmmap::FoliumMap)
    Base.show(io, "text/html", flmmap)
end

# for nice plots everywhere else
function Base.show(io::IO, mime::MIME"text/html", flmmap::FoliumMap)
    ms = splice_background(flmmap)
    write(io, ms)
end

# this takes a list like: [(minlat, minlon), (maxlat, maxlon)]
fit_bounds!(flmmap, bounds) = flmmap.obj.fit_bounds(bounds)

export FoliumMap
export draw, draw!, fit_bounds!, draw_colorbar!

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

default_colorscheme(colors_element::Integer) = colorschemes[:tableau_10]
default_colorscheme(colors_element::Real) = colorschemes[:inferno]
default_colorscheme(colors_element) = throw(ArgumentError("Color has to be either a String, Symbol, or vector of Strings, Symbols or real numbers"))


# cases where color is something else than a number (or vector of numbers...)
process_colors(cmap, ::Nothing, clims) = Iterators.cycle(["#3388ff"])
function process_colors(cmap, colors, clims)
    if colors isa String
        return Iterators.cycle([colors])
    else
        try
            iterate(colors)
            return Iterators.cycle(colors)
        catch e
            if e isa MethodError
                return Iterators.cycle([colors])
            else
                rethrow(e)
            end
        end
    end
end

process_colors(cmap, colors::Real, clims) = process_colors(cmap, [colors], clims)
process_colors(cmap::Nothing, colors::Real, clims) = process_colors(default_colorscheme(colors), [colors], clims)
process_colors(cmap, colors::Vector{<:Real}, clims) = _process_colors(cmap, colors, clims)
process_colors(cmap::Nothing, colors::Vector{<:Real}, clims) = _process_colors(default_colorscheme(first(colors)), colors, clims)

function trygetcmap(cmap)
    try
        return colorschemes[Symbol(cmap)]
    catch e
        if e isa KeyError
            rethrow(ErrorException("The colorscheme with key $cmap does not exists. Possible options for that key are: \n$(findcolorscheme(string(cmap)))."))
        else
            rethrow(e)
        end
    end
end

function _process_colors(cmap, colors::Vector{<:Integer}, clims)
    if cmap isa Symbol || cmap isa String
        cmap = trygetcmap(cmap)
    end
    colors = cmap[mod1.(colors, length(cmap))]
    return Iterators.cycle("#" .* hex.(colors))
end
function _process_colors(cmap, colors::Vector{<:Real}, clims)
    if cmap isa Symbol || cmap isa String
        cmap = trygetcmap(cmap)
    end
    return Iterators.cycle("#" .* hex.(get(cmap, colors, clims)))
end

# passthrough, if we just pass the figure, dont change anything
draw!(fig::FoliumMap; kwargs...) = fig

# main entry point for all mutating draws. Calls _draw with cleaned up arguments
function draw!(fig::FoliumMap, args...; kwargs...)
    #= leaflet has various color attributes:
    - color: color of stroke
    - fill_color: color of the fill (defaults to color)
    I guess for the time beeing, we just look at the color...
    =#
    colors = process_colors(get(kwargs, :cmap, nothing), get(kwargs, :color, nothing), get(kwargs, :clims, :extrema))
    tooltip = get(kwargs, :tooltip, get(kwargs, :color, 0.0))
    try
        if tooltip isa String
            tooltip = Iterators.cycle([tooltip])
        else
            iterate(tooltip)
            tooltip = Iterators.cycle(tooltip)
        end
    catch e
        if e isa MethodError
            tooltip = Iterators.cycle([tooltip])
        else
            rethrow(e)
        end
    end
    _draw!(fig, args...; kwargs..., tooltip=tooltip, colors=colors)
end

function draw(args...; figure_params=Dict(), kwargs...)
    @nospecialize
    fig = FoliumMap(; figure_params...)
    draw!(fig, args...; kwargs...)
    if !haskey(figure_params, :location)
        bounds = fig.obj.get_bounds()
        if !any(isnothing, bounds)
            fig.obj.fit_bounds(eachrow(bounds) |> collect)
        end
    end
    return fig
end

function _draw!(fig::FoliumMap, geometry; kwargs...)
    try
        # first, try to loop over everything
        for (geo, c, tt) in zip(geometry, kwargs[:colors], kwargs[:tooltip])
            @assert isgeometry(geo) "GeoInterface says that $geo is not a geometry."
            _draw!(fig, geomtrait(geo), geo; kwargs..., tooltip=tt, color=c)
        end
    catch e
        # if it is not loopable, assume single geometry
        if e isa MethodError
            @assert isgeometry(geometry) "GeoInterface says that $geometry is not a geometry."
            _draw!(fig, geomtrait(geometry), geometry; kwargs..., tooltip=first(kwargs[:tooltip]), color=first(kwargs[:colors]))
        else
            rethrow(e)
        end
    end
    return fig
end

function _draw!(fig::FoliumMap, lon, lat, series_type::Symbol; kwargs...)
    layer_class = get_layer_class(series_type)
    fill = false
    fill_opacity = 0.2
    if series_type == :polygon
        # sensible defaults...?
        fill = get(kwargs, :fill, true)
        fill_opacity = get(kwargs, :fill_opacity, 1.0)
    end
    layer_class(collect(zip(lat, lon)); fill=fill, fill_opacity=fill_opacity, kwargs..., tooltip=first(kwargs[:tooltip])).add_to(fig.obj)
    return fig
end

function draw_text!(fig::FoliumMap, text, lon, lat; angle=0.0, align=:left, align_vertical=:center, fontsize=20)
    angle *= -1
    if align == :left
        trans_x = "0%"
    elseif align == :center
        trans_x = "50%"
    elseif align == :right
        trans_x = "100%"
    end
    if align_vertical == :center
        trans_y = "50%"
    elseif align_vertical == :top
        trans_y = "0%"
    elseif align_vertical == :bottom
        trans_y = "100%"
    end
    icon = Folium.flm.features.DivIcon(icon_size=(250000, 36), icon_anchor=(0, 0),
        html="""<div style=
        "border-width: 5px;
        border-color: red;
        border-style: none; 
        font-size: $(fontsize)px;
        transform-origin: $trans_x $trans_y;
        text-align: $align;
        transform: translate(-$trans_x, -$trans_y) rotate($(angle)deg);">$text</div>""")
    marker = Folium.flm.Marker((lat, lon), icon=icon).add_to(fig.obj)
    return fig
end

function draw_colorbar!(fig::FoliumMap, title, colors; cmap=nothing, clims=extrema(colors), label_pad=1.0, tick_angle=0.0, margin_bottom=0.1, margin_top=0.1)
    label_pad *= 360 / (2π * 6371)
    bounds = fig.obj.get_bounds()
    padding = 0.001
    width = 0.003
    top = bounds[2, 1]
    bottom = bounds[1, 1]
    height = top - bottom
    bottom += height * margin_bottom
    top -= height * margin_top

    right_edge = bounds[2, 2] + padding
    map_resolution = 100
    colors = first(process_colors(cmap, range(clims..., map_resolution) |> collect, clims), map_resolution)
    vertical_subdivisions = range(bottom, top, map_resolution + 1)
    for (l, h, c) in zip(vertical_subdivisions[1:end-1], vertical_subdivisions[2:end], colors)
        draw!(fig, [right_edge, right_edge + width, right_edge + width, right_edge], [l, l, h, h], :polygon, color=c)
    end
    value_locs = range(bottom, top, 10)
    values = range(clims..., 10)
    for (v, vy) in zip(values, value_locs)
        draw_text!(fig, round(v, digits=2), right_edge + padding + width, vy, angle=tick_angle)
    end

    draw_text!(fig, title, right_edge + 2padding + width + label_pad, (top + bottom) / 2; angle=90, align=:center, align_vertical=:top, fontsize=30)
    return fig
end

include("geoplotting.jl")
end
