create table raw(a varchar, lon double precision, lat double precision);
\copy raw from walmart.csv with csv

CREATE TABLE multi AS
  SELECT
    ST_Multi(
      ST_Collect(
        ST_SetSRID(ST_Point(lon, lat), 4326)
      )
    ) as geom
  FROM
    "raw"
;

DROP TABLE "raw";
