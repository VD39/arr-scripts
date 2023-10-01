#!/usr/bin/env bash

###
# - Be sure to set your host name to match your Radarr host.
# - In Sonarr go to Settings > Connect > + > Custom Script.
# - Set your chosen name for this script.
# - Set your notification triggers:
#   - On Import
#   - Optional triggers:
#     - On Movie Delete
#     - On Movie File Delete
#     - On Movie File Delete For Upgrade
# - Set path to where to added this file.
###

# Exit if testing.
if [[ $radarr_eventtype == "Test" ]]; then
  exit 0
fi

# Update hostname an to match your server.
HOST_NAME="#"

# Log file.
LOG_FILE="/config/logs/delete_downloaded_film.txt"

# API key fetched automatically from config.
API_KEY="$(xmlstarlet sel -t -c "string(/Config/ApiKey)" /config/config.xml)"

# Log data to console and $LOG_FILE.
log () {
  log_time="$(date "+%d-%m%Y %r")"
  echo "$log_time :: $1" | tee -a $LOG_FILE
}

# Delete film from Radarr.
delete_downloaded_film() {
  log "Making request to delete film $radarr_movie_title (ID: $radarr_movie_id) from Radarr"

  # Make response to Radarr.
  response=$(
    curl \
    --silent --write-out "%{http_code}" \
    --request DELETE "$HOST_NAME/api/v3/movie/$radarr_movie_id?deleteFiles=false&addImportExclusion=false" \
    --header "accept: */*" \
    --header "X-Api-Key: $API_KEY"
  )

  http_status_code="${response:len-3}"

  # Log info based on if success or not.
  if [[ $http_status_code != "200" ]]; then
    log "The response returned a HTTP status code: $http_status_code"
    log "The response was: ${response::-3}"
  else
    log "Sucessfully deleted film $radarr_movie_title (ID: $radarr_movie_id) from Radarr"
  fi
}


# Truncate log file when size limit is reached.
if [[ -f $LOG_FILE ]]; then
  find $LOG_FILE -size +3000k -exec truncate $LOG_FILE --size 0 {} \;
else
  touch $LOG_FILE
fi

# Allow read and write only.
chmod 666 $LOG_FILE

# If film id exsits, then delete film from Radarr.
if [[ -n $radarr_movie_id ]]; then
  delete_downloaded_film
else
  log "No Film ID"
fi

exit 0
