using Folium
using Test
using ArchGDAL

@testset "Geometry Traits" begin
    point = ArchGDAL.createpoint()
    line = ArchGDAL.createlinestring()
    poly = ArchGDAL.createpolygon()

    multipoint = ArchGDAL.createmultipoint()
    multiline = ArchGDAL.createmultilinestring()
    multipoly = ArchGDAL.createmultipolygon()

    collection = ArchGDAL.creategeomcollection()

    for i in [point, line, poly, multipoint, multiline, multipoly, collection]
        draw(i)
    end
end
