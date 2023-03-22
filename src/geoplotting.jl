getcoords(geo) = getcoords(geomtrait(geo), geo)
getcoords(::LineStringTrait, geo) = [reverse(collect(getcoord(point))) for point in getgeom(geo)]

# Single geometries
function _draw!(fig, ::PointTrait, geometry; kwargs...)
    seriestype = get(kwargs, :seriestype, :circle)
    lon = getcoord(geometry, 1)
    lat = getcoord(geometry, 2)
    if seriestype === :circle
        flm.Circle((lat, lon); kwargs...).add_to(fig.obj)
    elseif seriestype === :marker
        flm.CircleMarker((lat, lon); kwargs...).add_to(fig.obj)
    else
        throw(ArgumentError("seriestype of $seriestype for is not implemented for points. Available types are: [:circle, :marker]"))
    end
    return fig
end

function _draw!(fig, ::LineStringTrait, geometry; kwargs...)
    coords = getcoords(geometry)
    flm.PolyLine(coords; kwargs...).add_to(fig.obj)
    return fig
end

function _draw!(fig, ::PolygonTrait, geometry; kwargs...)
    draw_internals = get(kwargs, :draw_internals, true)

    # sensible defaults...?
    fill = get(kwargs, :fill, true)
    fill_opacity = get(kwargs, :fill_opacity, 1.0)
    stroke = get(kwargs, :stroke, false)

    outside = getgeom(geometry, 1)
    coords = getcoords(outside)
    flm.Polygon(coords; fill=fill, fill_opacity=fill_opacity, stroke=stroke, kwargs...).add_to(fig.obj)
    if draw_internals
        for inner in Iterators.drop(getgeom(geometry), 1)
            coords = getcoords(inner)
            flm.Polygon(coords; kwargs...,
                fill=fill,
                fill_opacity=fill_opacity,
                fill_color="white",
                stroke=stroke).add_to(fig.obj)
        end
    end
    return fig
end

# AbstractGeometryCollectionTrait
# TODO: how should we pass the seriestype down to the point drawers?
function _draw!(fig, ::T, geometry; kwargs...) where {T<:AbstractGeometryCollectionTrait}
    for geo in getgeom(geometry)
        draw!(fig, geo; kwargs...)
    end
    return fig
end