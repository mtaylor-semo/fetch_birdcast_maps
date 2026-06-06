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

# Modified from https://stackoverflow.com/a/68550338/3832941
latitude = 37.132025
longitude = -89.461307

spring_start_date = "20260315"
spring_end_date = "20260531"
spring_dates <- seq(ymd(spring_start_date),ymd(spring_end_date), by = "days")

# DECIDE HOW TO HANDLE FALL AND SPRING


# Images are stored by GMT, but show EST on the image.
spring_sunsets <- getSunlightTimes(spring_dates,latitude,longitude,tz = "GMT")$sunset

# Add two hours to GMT to get two hours after sunset, using lubridate
spring_sunsets_plus_two <- spring_sunsets + hours(2)

# Round to nearest 10 minutes
spring_sunsets_plus_two <- ceiling_date(spring_sunsets_plus_two, "10 minutes")

sunset_length <- length(spring_sunsets_plus_two)
sunset_length <- length(fall_sunsets_plus_two)
# Alternative
# sunsets_plus_two <- sunsets_plus_two <- sunsets + 2*60*60

# Birdcast seems to put the night's images in the next day's date.
# e.g., The night of 202605 is stored in 202606
# https://is-birdcast-observed-prod.s3.us-east-1.amazonaws.com/mosaic/2026/03/17/mosaic_202603170210.jpg

base_url <- "https://is-birdcast-observed-prod.s3.us-east-1.amazonaws.com/mosaic/"

url_frag <- paste0(
  year(spring_sunsets_plus_two),
  "/0",
  month(spring_sunsets_plus_two),
  "/"
)

for (i in 1:sunset_length) {
  if (day(spring_sunsets_plus_two[i]) < 10)
    url_frag[i] = paste0(url_frag[i], "0", day(spring_sunsets_plus_two[i]), "/")
  else
    url_frag[i] = paste0(url_frag[i], day(spring_sunsets_plus_two[i]), "/")
}



image_name <- paste0(
  "mosaic_",
  year(spring_sunsets_plus_two),
  "0", month(spring_sunsets_plus_two))

for (i in 1:sunset_length) {
  if (day(spring_sunsets_plus_two[i]) < 10)
    image_name[i] = paste0(image_name[i], "0", day(spring_sunsets_plus_two[i]))
  else
    image_name[i] = paste0(image_name[i], day(spring_sunsets_plus_two[i]))
}


for (i in 1:sunset_length) {
  if (length(hour(spring_sunsets_plus_two[i])) == 1)
      image_name[i] = paste0(image_name[i], "0", hour(spring_sunsets_plus_two[i]))
  else
    image_name[i] = paste0(image_name[i], hour(spring_sunsets_plus_two[i]))
}

for (i in 1:sunset_length) {
  if (minute(spring_sunsets_plus_two[i]) < 10)
    image_name[i] = paste0(image_name[i], "0", minute(spring_sunsets_plus_two[i]), ".jpg")
  else
    image_name[i] = paste0(image_name[i], minute(spring_sunsets_plus_two[i]), ".jpg")
}

final_urls <- ""

for (i in 1:sunset_length) {
  final_urls[i] <- paste0(base_url, url_frag[i], image_name[i])
}

local_files <- str_glue("maps/{image_name}")


safe_download <- safely(~ download.file(.x, .y, mode = "wb"))

walk2(final_urls, local_files, safe_download)
