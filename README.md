# MyMeteo - MeteoStation Finder 🌦️
A program that locates the nearest meteorological station in Poland and retrieves weather data (e.g., air temperature, air pressure) for a given city. Implemented in both Bash and Python. The script automatically searches for the city coordinates, finds the nearest weather station and presents current weather data.

## Features
- 🌍 Automatic search for city coordinates
- 🌡️ Downloading current weather data
- 📍 Finding the nearest weather station
- 🔍 Detailed information about weather conditions
- 🛡️ Secure queries respecting the API usage policy

## System Requirements (for python script)
- Python 3.11 and higher
- Libraries:
- requests
- math
- argparse
  
## Clone the repository
```
git clone https://github.com/asztark/MyMeteo.git
cd MyMeteo
```
## Installation of 'requests' package for python script
```python
# Open terminal and type: 
pip install requests
```
## Usage 
### Bash
```bash
bash mymeteo.sh [city]
```
##### Examples 
```bash
bash mymeteo.sh Warszawa 
```
```bash
bash mymeteo.sh Kalisz
```
### Python
```python
python .\MyMeteo.py [city]
```
##### Examples
```python
python .\MyMeteo.py Warszawa 
```
```python
python .\MyMeteo.py Kalisz
```

## Output example
```
Warszawa 12375
Measurement date: 2025-05-05
Measurement time: 19

Temperature:         8.3 °C
Wind speed:          2 m/s
Wind direction:      310 °
Relative humidity:   54.7 %
Precipitation total: 0 mm
Pressure:            1017.3 hPa
```
## Used APIs
### OpenStreetMap Nominatim API - city cooridantes
https://nominatim.org/
### Instytut Meteorologii i Gospodarki Wodnej (IMGW) API - weather data
https://danepubliczne.imgw.pl/pl/apiinfo
