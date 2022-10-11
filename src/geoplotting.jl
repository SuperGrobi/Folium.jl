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

# multi geometries of same kind

function _draw!(fig, ::MultiPointTrait, geometry; kwargs...)
    println("now plotting a MultiPoint")
end

function _draw!(fig, ::MultiLineStringTrait, geometry; kwargs...)
    println("now plotting a MultiLineString")
end

function _draw!(fig, ::MultiPolygonTrait, geometry; kwargs...)
    println("now plotting a MultiPolygon")
end

# multiple geometries, different kinds

function _draw!(fig, ::GeometryCollectionTrait, geometry; kwargs...)
    println("now plotting a GeometryCollection")
end