# Script to fetch daily Birdcast maps. Time will be set for two hours 
# after local sunset, based on location of Miller Reserve.

# Have to determine local sunset time, round up to closest 10 minutes, then
# add two hours.  Birdcast maps are static jpg images made every 10 minutes.

# Base URL format to download life maps is
# For year YYYY, month MM, day DD, hour HH, minute MM (rounded to 10 mins intervals):
#  https://is-birdcast-observed-prod.s3.us-east-1.amazonaws.com/mosaic/YYYY/MM/DD/mosaic_YYYYMMDDHHmm.jpg
# Example for 28 Apr 2026 22:00 UTC:
#  https://is-birdcast-observed-prod.s3.us-east-1.amazonaws.com/mosaic/2026/04/28/mosaic_202604282200.jpg

# Map images are in Eastern Standard Time (EST)


# Packages ----------------------------------------------------------------

library(tidyverse)
library(suncalc)


# Constants ---------------------------------------------------------------

# Constants
# Miller is GMT-6, but see https://en.wikipedia.org/wiki/Tz_database#Area
# for explanation why the sign is inverted for Etc codes.
time_zone <- "Etc/GMT+6"

# GMT+7 should equate to two hours after sunset for Miller Reserve.
# For example, 18:00 CST is 19:00 EST, plus two more hours for delay
# after sunset.

map_time_zone <- "Etc/GMT+7"

# First attempt at getting sunrise and sunset times. Note that
# 'Etc/GMT+6' is Olson Code for central standard time. The recorders
# will be kept in standard time, never daylight savings time.
# fred <- getSunlightTimes(
#   date = as.Date("2026-03-11"), 
#   lat = 37.132025, 
#   lon = -89.461307,
#   tz = tzone, 
#   keep = c("sunrise", "sunset"))


# Create a tibble with date, sunrise, and sunset for Miller Reserve.
# NOTE: The times for New Madrid (Prairie) recorder are probably close enough
# but determine if need a separate set for that recorder in the winter.

# Modified from https://stackoverflow.com/a/68550338/3832941
start_date = "20260315"
end_date = "20260531"
Dates <- seq(ymd(start_date),ymd(end_date), by = "days")
latitude = 37.132025
longitude = -89.461307


sunsets <- getSunlightTimes(Dates,latitude,longitude,tz = "GMT")$sunset

# Add two hours to GMT to get two hours after sunset, using lubridate
sunsets_plus_two <- sunsets + hours(2)

# Round to nearest 10 minutes
sunsets_plus_two <- round_date(sunsets_plus_two, "10 minutes")

sunset_length <- length(sunsets_plus_two)

# Alternative
# sunsets_plus_two <- sunsets_plus_two <- sunsets + 2*60*60

# Birdcast seems to put the night's images in the next day's date.
# e.g., The night of 202605 is stored in 202606

https://is-birdcast-observed-prod.s3.us-east-1.amazonaws.com/mosaic/2026/03/17/mosaic_202603170210.jpg

base_url <- "https://is-birdcast-observed-prod.s3.us-east-1.amazonaws.com/mosaic/"

url_frag <- paste0(
  year(sunsets_plus_two),
  "/0",
  month(sunsets_plus_two),
  "/"
)

for (i in 1:sunset_length) {
  if (day(sunsets_plus_two[i]) < 10)
    url_frag[i] = paste0(url_frag[i], "0", day(sunsets_plus_two[i]), "/")
  else
    url_frag[i] = paste0(url_frag[i], day(sunsets_plus_two[i]), "/")
}



image_name <- paste0(
  "mosaic_",
  year(sunsets_plus_two),
  "0", month(sunsets_plus_two))

for (i in 1:sunset_length) {
  if (day(sunsets_plus_two[i]) < 10)
    image_name[i] = paste0(image_name[i], "0", day(sunsets_plus_two[i]))
  else
    image_name[i] = paste0(image_name[i], day(sunsets_plus_two[i]))
}


for (i in 1:sunset_length) {
  if (length(hour(sunsets_plus_two[i])) == 1)
      image_name[i] = paste0(image_name[i], "0", hour(sunsets_plus_two[i]))
  else
    image_name[i] = paste0(image_name[i], hour(sunsets_plus_two[i]))
}

for (i in 1:sunset_length) {
  if (minute(sunsets_plus_two[i]) < 10)
    image_name[i] = paste0(image_name[i], "0", minute(sunsets_plus_two[i]), ".jpg")
  else
    image_name[i] = paste0(image_name[i], minute(sunsets_plus_two[i]), ".jpg")
}

final_urls <- ""

for (i in 1:sunset_length) {
  final_urls[i] <- paste0(base_url, url_frag[i], image_name[i])
}

local_files <- str_glue("maps/{image_name}")


safe_download <- safely(~ download.file(.x, .y, mode = "wb"))

walk2(final_urls, local_files, safe_download)
