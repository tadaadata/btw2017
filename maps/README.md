# Getting the map data

There are two sources for our underlying maps. Both are publicly available:

- the [voter districts](https://www.bundeswahlleiter.de/bundestagswahlen/2017/wahlkreiseinteilung/downloads.html):  
  scroll down to the (SHP) shapefiles; I don't know the difference between the available two but I guess it doesn't make much of a difference - for now we're using the generalized version, specifically `https://www.bundeswahlleiter.de/dam/jcr/f92e42fa-44f1-47e5-b775-924926b34268/btw17_geometrie_wahlkreise_geo_shp.zip`, which needs to ne extracted and the folder renamed to `bwl_shapefile`.
 
- the [GADM map of Germany (level 1)](http://gadm.org/download):  
  again, I don't know if this is actually necessary, but for now it is a convenient way to map data to the federal states, since the data is alredy in a format easily readable by R without any extra fiddling around. Specifically we used `http://biogeo.ucdavis.edu/data/gadm2.8/rds/DEU_adm1.rds`.
