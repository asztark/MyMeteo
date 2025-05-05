import sys
import argparse
import requests  # type: ignore
import math

def help():
    """Displays script usage information"""
    parser = argparse.ArgumentParser(description='Find the nearest weather station for a given city in Poland.')
    parser.add_argument('city', type=str, help='City for which to find the nearest weather station')
    parser.add_argument('--debug', '--verbose', action='store_true', help='Enable debug mode')
    return parser

def haversine(lat1, lon1, lat2, lon2):
    """Calculates the distance between two geographic points"""
    # Convert degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])

    # Radius of the Earth in kilometers
    R = 6371

    # Calculate differences
    dlat = lat2 - lat1
    dlon = lon2 - lon1

    # Haversine formula
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))

    # Calculate distance
    distance = R * c
    return distance

def debug_print(message, debug_mode):
    """Displays debug messages"""
    if debug_mode:
        print(f"[DEBUG] {message}")

def main():
    # Parse arguments
    parser = help()
    args = parser.parse_args()
    city = args.city
    debug_mode = args.debug
    headers = {
        'Referer': 'https://www.google.com/',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }

    # Fetch city data
    debug_print(f"Fetching data from Nominatim for city: {city}", debug_mode)
    nominatim_url = f"https://nominatim.openstreetmap.org/search?q={city}&format=json&limit=1&countrycodes=pl"
    nominatim_response = requests.get(url=nominatim_url, headers=headers)
    nominatim_data = nominatim_response.json()

    if not nominatim_data:
        print(f"Error: City {city} not found")
        sys.exit(1)

    lat = float(nominatim_data[0]['lat'])
    lon = float(nominatim_data[0]['lon'])
    debug_print(f"City coordinates - Latitude: {lat}, Longitude: {lon}", debug_mode)

    # Fetch weather station data
    debug_print("Fetching data from IMGW", debug_mode)
    imgw_url = "https://danepubliczne.imgw.pl/api/data/synop"
    imgw_response = requests.get(url=imgw_url, headers=headers)
    imgw_data = imgw_response.json()

    # Find the nearest station
    min_distance = float('inf')
    closest_station = None

    for station in imgw_data:
        debug_print(f"Processing station: {station['stacja']}", debug_mode)
        station_url = f"https://nominatim.openstreetmap.org/search?q={station['stacja']}&format=json&limit=1&countrycodes=pl"
        station_response = requests.get(url=station_url, headers=headers)
        station_data = station_response.json()
        
        if not station_data:
            continue
        
        lat1 = float(station_data[0]['lat'])
        lon1 = float(station_data[0]['lon'])
        
        distance = haversine(lat, lon, lat1, lon1)
        debug_print(f"Distance to station {station['stacja']}: {distance} km", debug_mode)
        
        if distance < min_distance:
            min_distance = distance
            closest_station = station

    # Displaying weather data
    if closest_station:
        print(f"{closest_station['stacja']} {closest_station['id_stacji']}")
        print(f"Measurement date: {closest_station['data_pomiaru']}")
        print(f"Measurement time: {closest_station['godzina_pomiaru']}")
        print("")
        print(f"Temperature:         {closest_station['temperatura']} °C")
        print(f"Wind speed:          {closest_station['predkosc_wiatru']} m/s")
        print(f"Wind direction:      {closest_station['kierunek_wiatru']} °")
        print(f"Relative humidity:   {closest_station['wilgotnosc_wzgledna']} %")
        print(f"Precipitation total: {closest_station['suma_opadu']} mm")
        print(f"Pressure:            {closest_station['cisnienie']} hPa")
    else:
        print("No meteorological station found.")

if __name__ == "__main__":
    main()
