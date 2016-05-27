BEGIN;

-- Table which has each POINT of the `multi` MULTIPOINT and its associated UTM
-- TODO: There's a Y component to UTM
CREATE TABLE points_by_utm AS
  SELECT
    (points.point).geom as geom,
    floor((ST_X((points.point).geom)+180)/6)+1 as utm
  FROM
    (SELECT ST_Dump(geom) as point FROM multi) points
;

-- Merge all the POINTS for each UTM as a MULTIPOINT
CREATE TABLE multipoints_by_utm AS
  SELECT
    ST_Multi(
      ST_Collect(geom)
    ) as geom
  FROM
    points_by_utm
  GROUP BY
    utm
;

-- Buffer each MULTIPOINT (one for each UTM)
CREATE TABLE buffered_by_utm AS
  SELECT
    ST_Transform(
      ST_Buffer(
        ST_Transform(geom, _ST_BestSRID(geom)),
        800
      ),
      4326
    ) as geom
  FROM
    multipoints_by_utm
;

-- Union each buffered MULTIPOINT (now a POLYGON) together
CREATE TABLE buffered_points AS
  SELECT
    ST_Union(geom) as geom
  FROM
    buffered_by_utm
;

-- Limit the view to the greater NYC area, and dump the results to a geojson
-- file
CREATE TABLE geojson AS
  SELECT
    ST_AsGeoJSON(
      ST_Intersection(
        geom,
        ST_SetSRID('POLYGON((-75.17 41.57, -72.92 41.57, -72.92 39.73, -75.17 39.73, -75.17 41.57))'::geometry, 4326)
      )
    )
  FROM
    buffered_points
;

\copy (select * from geojson) to 'points.json';

ROLLBACK;
