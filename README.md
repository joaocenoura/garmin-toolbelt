Garmin Toolbelt
==================

This project provides a small set of tools to generate gmapsupp.img with
contours from OSM.

It provides a simple to use bash script that abstracts all `splitter.jar`,
`mkgmap.jar` and `phyghtmap` interactions. Also fetches automatically those
binaries (except `phyghtmap`).

This project was tested in debian only. An alternative vagrant setup is also
available so you can run in any platform (OSX, Windows and other Linux flavors).

Configuration
----------------

Place `*.conf` files under `./maps`. Each configuration file will generate
a `gmapsupp.img`. Configuration file is a simple properties file with the
following fields:

- `map_name`: descriptive map name
- `map_url`: downloads map from given URL. Only tested with geofabrik.de
- `map_poly`: polygon file URL. Also tested with geofabrik.de

Example:

```
$ ls -la ./maps
ireland.conf portugal.conf

$ cat ./maps/portugal.conf
map_name="portugal"
map_url="http://download.geofabrik.de/europe/portugal-latest.osm.pbf"
map_poly="http://download.geofabrik.de/europe/portugal.poly"

$ cat ./maps/ireland.conf
map_name="ireland"
map_url="http://download.geofabrik.de/europe/ireland-and-northern-ireland-latest.osm.pbf"
map_poly="http://download.geofabrik.de/europe/ireland-and-northern-ireland.poly"
```

Generating maps
------------------

```
# usage of vagrant is optional
$ vagrant up
$ vagrant ssh

$ ./generate_gmap.sh
# ... this will take a while ...
# first run will take longer as it will download binaries, bounds and sea files
# those files are downloaded once and stored inside ./bin and ./tmp directories
# and are reused on subsequent runs
# maps defined in configuration files are also cached under ./tmp/maps directory

# list gmapsupp for each configuration file (map+contour)
$ ls -la ./tmp/*/*-*.img
-rw-r--r-- 1 joao joao 9.6M Oct 22 22:21 ./tmp/ireland/ireland-contours.img
-rw-r--r-- 1 joao joao  62M Oct 22 22:19 ./tmp/ireland/ireland-map.img
-rw-r--r-- 1 joao joao  18M Oct 22 22:17 ./tmp/portugal/portugal-contours.img
-rw-r--r-- 1 joao joao  54M Oct 22 22:12 ./tmp/portugal/portugal-map.img

# list single gmapsupp - combination of all generated maps
$ ls -lah ./tmp/single_gmap/gmapsupp.img
-rw-r--r-- 1 joao joao 143M Oct 22 22:21 ./tmp/single_gmap/gmapsupp.img

# copy desired maps into SD card, ./Garmin folder
```

Customizing it
-----------------

The current `./generate_gmap.sh` generate maps for trekking/cycling and  works
fine for my garmin etrex 20. Feel free to edit `./generate_gmap.sh` and adjust
it to your context.

References
------------

- [Mkgmap/help/How to create a map](http://wiki.openstreetmap.org/wiki/Mkgmap/help/How_to_create_a_map)
- [OSM Map on Garmin/Contours using phygtmap](http://wiki.openstreetmap.org/wiki/OSM_Map_on_Garmin/Contours_using_phygtmap)
- [OSM Map On Garmin/Cycle map](http://wiki.openstreetmap.org/wiki/OSM_Map_On_Garmin/Cycle_map)
- [Talk:OSM Map On Garmin/Cycle map](http://wiki.openstreetmap.org/wiki/Talk:OSM_Map_On_Garmin/Cycle_map)
- [mkgmap - Documentation](http://www.mkgmap.org.uk/doc/index.html)
- [openfietsmap - example](http://www.openfietsmap.nl/procedure/example)
- [openfietsmap - scripts](http://mijndev.openstreetmap.nl/~ligfietser/openfietsmap/Scripts)
