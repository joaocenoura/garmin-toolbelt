#!/bin/bash
set -e
BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BIN="$BASE/bin"
TMP="$BASE/tmp"
MAPS_CONF="$BASE/maps"
STYLE_PATH="$BASE/style/cyclemap"
STYLE_PATH_CUSTOM="$BASE/style/custom"
STYLE_PATH="$BASE/style/openfietsmap"
DOWNLOADS="$TMP/downloads"
HGT_DIR="$TMP/hgt"
LOG="$TMP/log"
MAPS="$TMP/maps"
MAP_BOUNDS=$MAPS/bounds.zip
MAP_SEA=$MAPS/sea.zip

MAP_NAME_INDEX="$TMP/map_index"

mkdir -p $BIN $MAPS_CONF $TMP $DOWNLOADS $HGT_DIR $LOG $MAPS

################################################################################
# core functions
################################################################################
function header {
    echo
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
}

function get_path {
    echo "$(realpath $1 --relative-to $BASE)"
}

function info {
    echo "[$1] $2"
}

function get_map_name {
    if [ ! -f "$MAP_NAME_INDEX" ]; then
        echo "10000000" > $MAP_NAME_INDEX
    fi
    local map_name=$(cat $MAP_NAME_INDEX)
    local new_map_name=$((map_name+1000))
    echo $new_map_name > $MAP_NAME_INDEX
    echo "$map_name"
}

################################################################################
# 1st level functions (depends on above functions)
################################################################################
function download {
    local filepath="$1"
    local url="$2"
    info "download" "from: $url"
    info "download" "  to: $filepath"
    tmp_file=$(mktemp)
    wget -q --show-progress $url -O $tmp_file
    mv $tmp_file $filepath
}

################################################################################
# 2nd level functions (depends on above functions)
################################################################################
function download_once {
    local filepath="$1"
    local url="$2"
    if [ ! -f "$filepath" ]; then
        download $filepath $url
    else
        info "download" "skipping... already exists: $(get_path $filepath)"
    fi
}

function bin_download {
    local bin_name="$1"
    local url="$2"
    local filename="$(basename $url)"
    local filepath="$BIN/$filename"
    if [ ! -f "$filepath" ]; then
        info "bin_download" "downloading $bin_name"
        download $filepath $url
    else
        info "bin_download" "$bin_name updated"
    fi
    ln -sf $filepath $BIN/$bin_name
}

function zip_download {
    local bin_name="$1"
    local url="$2"
    local filename="$(basename $url)"
    local download_path="$DOWNLOADS/$filename"
    local folder=${filename%.*}
    local bin_app_folder="$BIN/$folder"
    local bin_link=$BIN/$bin_name

    if [ ! -d "$bin_app_folder" ]; then
        info "zip_download" "downloading $bin_name"
        download_once $download_path $url
        unzip -qo $download_path -d $BIN
    else
        info "zip_download" "$bin_name updated"
    fi
    local jar_file=$(readlink -f $bin_app_folder/*.jar)
    ln -sf $jar_file $bin_link
}

function map_download {
    local filepath="$1"
    local filename="$(basename $filepath)"
    local map_url="$2"
    if [ ! -f "$filepath" ] || test `find "$filepath" -mmin +604800`; then
        info "map_download" "downloading $filename..."
        download $filepath $map_url
    else
        info "map_download" "skipping $filename - updated less than 1 week"
    fi
}

################################################################################
function split_map {
    local map_file="$1"
    local split_dir="$2"
    local poly="$3"
    local map_id="$(get_map_name)"

    header "Splitter for $1"
    info   "variables" " map_file=$map_file"
    info   "variables" "split_dir=$split_dir"
    info   "variables" "     poly=$poly"
    info   "variables" "   map_id=$map_id"

    java -jar $BIN/splitter.jar \
         --max-nodes=900000 \
         --mapid=$map_id \
         --polygon-file=$poly \
         --precomp-sea=$MAP_SEA \
         --output-dir=$split_dir \
         $map_file > $LOG/splitter.log
}

function make_gmapsupp {
    local map_description="$1"
    local split_dir="$2"
    local mkgmap_dir="$3"
    local map_name="$(get_map_name)"

    header "Make gmapsupp for $1"
    info   "variables" "map_description=$map_description"
    info   "variables" "      split_dir=$split_dir"
    info   "variables" "     mkgmap_dir=$mkgmap_dir"
    info   "variables" "       map_name=$map_name"

    java -jar $BIN/mkgmap.jar \
         --max-jobs \
         --bounds=$MAP_BOUNDS \
         --precomp-sea=$MAP_SEA \
         --gmapsupp \
         -n "$map_name" \
         --description="${map_description}-map" \
         --route \
         --cycle-map \
         --add-pois-to-areas \
         --index \
         --remove-short-arcs --levels="0=24, 1=22, 2=21, 3=19, 4=18, 5=16" --location-autofill=3 \
         --style-file=$STYLE_PATH \
         --output-dir=$mkgmap_dir \
         --read-config=$split_dir/template.args \
         ${STYLE_PATH}.typ > $LOG/make_gmapsupp.log &&
        mv $mkgmap_dir/gmapsupp.img $mkgmap_dir/../${map_description}-map.img

}

function make_contour {
    local map_description="$1"
    local contour_dir="$2/contour"
    local poly="$3"
    local map_name="$(get_map_name)"
    mkdir -p $contour_dir $contour_dir/data $contour_dir/contours

    header "Make contour map for $1"
    info   "variables" "map_description=$map_description"
    info   "variables" "    contour_dir=$contour_dir"
    info   "variables" "     styles_dir=$styles_dir"
    info   "variables" "      split_dir=$split_dir"
    info   "variables" "       map_name=$map_name"

    cd $contour_dir/contours &&
        phyghtmap\
            --jobs=8 \
            --hgtdir=$HGT_DIR \
            --data-source=view3,srtm3,srtm1 \
            --step=20 \
            --line-cat=400,100 \
            --polygon=$poly \
            --pbf \
            --output-prefix=contour > $LOG/make_contour.log

    cd $contour_dir &&
        java -Xmx2048M -jar $BIN/mkgmap.jar \
             --max-jobs \
             --bounds=$MAP_BOUNDS \
             --precomp-sea=$MAP_SEA \
             --gmapsupp \
             --mapname="$map_name" \
             --description="${map_description}-contours" \
             --style-file=$STYLE_PATH_CUSTOM \
             --read-config=$STYLE_PATH_CUSTOM/options \
             ${STYLE_PATH_CUSTOM}.typ $contour_dir/contours/*.pbf >> $LOG/make_contour.log &&
        mv $contour_dir/gmapsupp.img $contour_dir/../${map_description}-contours.img

    echo "mv $contour_dir/gmapsupp.img $contour_dir/../${map_description}-contours.img"
}

function make_one_gmapsupp {
    local final_dir="$TMP/single_gmap"
    mkdir -p $final_dir
    rm -rf $final_dir/*

    header "Make single gmapsupp"
    info   "variables" "final_gmapsupp=$final_dir"
    info   "variables" "input files:"
    ls -lah $TMP/*/*-*.img

    java -Xmx2048M -jar $BIN/mkgmap.jar \
         --gmapsupp \
         --output-dir=$final_dir \
         $TMP/*/*-*.img > $LOG/make_one_gmapsupp.log
}

################################################################################
# entry point
################################################################################
zip_download "mkgmap.jar"    "http://www.mkgmap.org.uk/download/mkgmap-r3698.zip"
zip_download "splitter.jar"  "http://www.mkgmap.org.uk/download/splitter-r439.zip"
bin_download "GpsMaster.jar" "http://gpsmaster.org/download/GpsMaster_0.61.00.jar"

map_download $MAP_BOUNDS "http://osm2.pleiades.uni-wuppertal.de/bounds/latest/bounds.zip"
map_download $MAP_SEA    "http://osm2.pleiades.uni-wuppertal.de/sea/latest/sea.zip"

# look for empty dir
if ! [ "$(ls -A $MAPS_CONF)" ]; then
    echo "Please create configuration files under $MAPS_CONF"
    exit 1
fi

# foreach configured map
find $MAPS_CONF -type f -name "*.conf" | sort | while read conf; do
    source $conf
    cwd="$TMP/$map_name"
    split_dir="$cwd/split"
    mkgmap_dir="$cwd/mkgmap"

    # clean previous run
    rm -rf $cwd
    mkdir -p $cwd $split_dir $mkgmap_dir

    downloaded_map="$MAPS/$(basename $map_url)"
    poly_file="$MAPS/${map_name}.poly"

    header "Preparing garmin map for $map_name"
    info "variables" "       map_url=$map_url"
    info "variables" "      map_poly=$map_poly"
    info "variables" "   working dir=$(get_path $cwd)"
    info "variables" "downloaded_map=$(get_path $downloaded_map)"

    map_download  $poly_file      $map_poly
    map_download  $downloaded_map $map_url
    split_map     $downloaded_map $split_dir $poly_file
    make_gmapsupp $map_name       $split_dir $mkgmap_dir
    make_contour  $map_name      $cwd       $poly_file
done

# finally, merge all gmapsupp into one
make_one_gmapsupp
