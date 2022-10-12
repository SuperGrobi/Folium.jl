using Folium
using Test
using ArchGDAL

@testset "Geometry Traits" begin
    point = ArchGDAL.createpoint(40.0, 2.0)
    point2 = ArchGDAL.createpoint(20.0, 0.5)
    line = ArchGDAL.createlinestring([1.0, 1.0, 1.0], [0.0, 4.8, 2.9])
    line2 = ArchGDAL.createlinestring([0.3, 0.3, 0.3], [0.3, 4.3, 3.6])
    poly = ArchGDAL.fromWKT("POLYGON ((-5 -5,5 -5,5 5,-5 5,-5 -5),(-1.5 -2.5,3.5 -2.5,3.5 2.5,-1.5 2.5,-1.5 -2.5),(0.75 -3.25,1.25 -3.25,1.25 -2.75,0.75 -2.75,0.75 -3.25))")
    poly2 = ArchGDAL.fromWKT("POLYGON ((0.0 -1.5,4.0 -1.5,4.0 5.5,0.0 5.5,0.0 -1.5))")

    multipoint = ArchGDAL.createmultipoint()
    ArchGDAL.addgeom!(multipoint, point)
    ArchGDAL.addgeom!(multipoint, point2)
    multiline = ArchGDAL.createmultilinestring()
    ArchGDAL.addgeom!(multiline, line)
    ArchGDAL.addgeom!(multiline, line2)
    multipoly = ArchGDAL.createmultipolygon()
    ArchGDAL.addgeom!(multipoly, poly)
    ArchGDAL.addgeom!(multipoly, poly2)

    collection = ArchGDAL.creategeomcollection()
    for i in [point, point2, line, line2, poly, poly2, multipoint, multiline, multipoly]
        ArchGDAL.addgeom!(collection, i)
    end

    println(collect(getgeom(line)))

    for i in [point, line, poly, multipoint, multiline, multipoly, collection]
        draw(i)
    end
    display(draw([point, point2]))
end

@testset "Array based geometry" begin
    plon = 40.0
    plat = 2.0
    linelon = [1.0, 1.0, 1.0] 
    linelat = [0.0, 4.8, 2.9]
    polylon = [0.0, 3.0, 3.0, 0.0, 0.0]
    polylat = [0.0, 0.0, 5.0, 6.0, 0.0]
    pointmap = draw(plon, plat, :circle)
    linemap = draw(linelon, linelat, :line)
    polymap = draw(polylon, polylat, :polygon)
    for m in [pointmap, linemap, polymap]
        display(m)
    end
end