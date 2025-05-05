#!/bin/bash

# Function to display script usage information
help() {
  echo "Usage: $0 [-h|--help] [--debug|--verbose] <city>"
  echo "Find the nearest weather station for the given city in Poland."
  echo
  echo "Options:"
  echo "  -h, --help       Display this help message and exit."
  echo "  --debug, --verbose  Enable debug mode to show the current script state."
  echo
  echo "Arguments:"
  echo "  <city>          The city for which to find the nearest weather station."
  exit 1
}

# Function to calculate the distance in km between two points using the Haversine formula
haversine() {
  lat1=$1
  lon1=$2
  lat2=$3
  lon2=$4

  # Convert degrees to radians
  lat1=$(echo "$lat1 * 3.141592653589793 / 180" | bc -l)
  lon1=$(echo "$lon1 * 3.141592653589793 / 180" | bc -l)
  lat2=$(echo "$lat2 * 3.141592653589793 / 180" | bc -l)
  lon2=$(echo "$lon2 * 3.141592653589793 / 180" | bc -l)

  # Radius of the Earth in kilometers
  R=6371

  # Calculate differences
  dlat=$(echo "$lat2 - $lat1" | bc -l)
  dlon=$(echo "$lon2 - $lon1" | bc -l)

  # Haversine formula
  a=$(echo "s($dlat / 2)^2 + c($lat1) * c($lat2) * s($dlon / 2)^2" | bc -l)
  c=$(echo "2 * a( sqrt($a) )" | bc -l)

  # Calculate distance
  distance=$(echo "$R * $c" | bc -l)
  echo $distance
}

# Function to display debug messages if debug mode is enabled
debug() {
  if [[ $debug_mode -eq 1 ]]; then
    echo "[DEBUG] $1"
  fi
}

# Parse command line options
debug_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help
      ;;
    --debug|--verbose)
      debug_mode=1
      shift
      ;;
    *)
      if [[ -z $city ]]; then
        city=$1
      else
        echo "Error: Too many arguments."
        help
      fi
      shift
      ;;
  esac
done

# Check if city is provided
if [[ -z $city ]]; then
  echo "Error: No city provided."
  help
fi

# Fetch data
debug "Fetching data from Nominatim for city: $city"
nominatim_url="https://nominatim.openstreetmap.org/search?q=${city}&format=json&limit=1&countrycodes=pl"
nominatim_data=$(wget -qO- $nominatim_url)
debug "Nominatim data: $nominatim_data"

debug "Fetching data from IMGW"
imgw_url="https://danepubliczne.imgw.pl/api/data/synop"
imgw_data=$(curl -s $imgw_url)
debug "IMGW data: $imgw_data"

# City coordinates
lat=$(echo $nominatim_data | jq -r .[].lat)
lon=$(echo $nominatim_data | jq -r .[].lon)
debug "City coordinates - Latitude: $lat, Longitude: $lon"

# List of stations
mapfile -t station_list < <(echo "$imgw_data" | jq -r .[].stacja)
debug "Station list: ${station_list[*]}"

# Variables to store the nearest station
min_distance=99999999
closest_station=""

# Loop through stations to find the nearest
for station in "${station_list[@]}"; do
  debug "Processing station: $station"
  data=$(wget -qO- "https://nominatim.openstreetmap.org/search?q=${station}&format=json&limit=1&countrycodes=pl")
  lat1=$(echo $data | jq -r .[].lat)
  lon1=$(echo $data | jq -r .[].lon)
  debug "Station coordinates - Latitude: $lat1, Longitude: $lon1"

  # Calculate distance
  distance=$(haversine $lat $lon $lat1 $lon1)
  debug "Distance to station $station: $distance km"

  # If distance is less than the minimum, update the nearest station
  if (( $(echo "$distance < $min_distance" | bc -l) )); then
    min_distance=$distance
    closest_station=$station
    debug "New nearest station: $closest_station (Distance: $min_distance km)"
  fi
done

# Data for the nearest station
debug "Fetching data for the nearest station: $closest_station"
nearest_station_data=$(echo "$imgw_data" | jq --arg closest_station "$closest_station" '.[] | select(.stacja == $closest_station)')

# Display weather data
station_name=$(echo "$nearest_station_data" | jq -r '.stacja')
station_id=$(echo "$nearest_station_data" | jq -r '.id_stacji')
date=$(echo "$nearest_station_data" | jq -r '.data_pomiaru')
time=$(echo "$nearest_station_data" | jq -r '.godzina_pomiaru')
temperature=$(echo "$nearest_station_data" | jq -r '.temperatura')
wind_speed=$(echo "$nearest_station_data" | jq -r '.predkosc_wiatru')
wind_direction=$(echo "$nearest_station_data" | jq -r '.kierunek_wiatru')
humidity=$(echo "$nearest_station_data" | jq -r '.wilgotnosc_wzgledna')
precipitation=$(echo "$nearest_station_data" | jq -r '.suma_opadu')
pressure=$(echo "$nearest_station_data" | jq -r '.cisnienie')

echo "$closest_station $station_id"
echo "Measurement date: $date"
echo "Measurement time: $time"
echo ""
echo "Temperature:         $temperature °C"
echo "Wind speed:          $wind_speed m/s"
echo "Wind direction:      $wind_direction °"
echo "Relative humidity:   $humidity %"
echo "Precipitation total: $precipitation mm"
echo "Pressure:            $pressure hPa"
