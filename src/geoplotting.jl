# Single geometries

function _draw!(fig, ::PointTrait, geometry; kwargs...)
    
    println("now plotting a Point")
end

function _draw!(fig, ::LineStringTrait, geometry; kwargs...)
    println("now plotting a LineString")
end

function _draw!(fig, ::PolygonTrait, geometry; kwargs...)
    println("now plotting a Polygon")
end

# AbstractGeometryCollectionTrait
function _draw!(fig, ::T, geometry; kwargs...) where {T<:AbstractGeometryCollectionTrait}
    println("now plotting a GeometryCollection")
    for geo in getgeom(geometry)
        draw!(fig, geo; kwargs...)
    end
    return fig
end