#!/usr/bin/env bash

###
# - Be sure to set your host name to match your Sonarr host.
# - In Sonarr go to Settings > Connect > + > Custom Script.
# - Set your chosen name for this script.
# - Set your notification triggers:
#   - On Import
#   - On Series Delete
#   - On Episode File Delete
#   - On Episode File Delete For Upgrade
# - Set path to where to added this file.
###

# Exit if testing.
if [[ $sonarr_eventtype == "Test" ]]; then
  exit 0
fi

# Update hostname an to match your server.
HOST_NAME="#"

# Log file.
LOG_FILE="/config/logs/unmonitor_downloaded_episodes.txt"

# API key fetched automatically from config.
API_KEY="$(xmlstarlet sel -t -c "string(/Config/ApiKey)" /config/config.xml)"

# Log data to console and $LOG_FILE.
log () {
  log_time="$(date "+%d-%m%Y %r")"
  echo "$log_time :: $1" | tee -a $LOG_FILE
}

# Unmonitor episode from Sonarr.
unmonitor_episode() {
  log "Making request to unmonitor episode $sonarr_episodefile_episodetitles (IDs: $sonarr_episodefile_episodeids) from series $sonarr_series_title from Sonarr"

  # Make response to Sonarr.
  response=$(
    curl \
    --silent --write-out "%{http_code}" \
    --request PUT $HOST_NAME/api/v3/episode/monitor \
    --header "accept: */*" \
    --header "Content-Type: application/json" \
    --header "X-Api-Key: $API_KEY" \
    --data "{ episodeIds: [$sonarr_episodefile_episodeids], monitored: false }"
  )

  http_status_code="${response:len-3}"

  # Log info based on if success or not.
  if [[ $http_status_code != "202" ]]; then
    log "The response returned a HTTP status code: $http_status_code"
    log "The response was: ${response::-3}"
  else
    log "Sucessfully unmonitored episode $sonarr_episodefile_episodetitles (IDs: $sonarr_episodefile_episodeids) from series $sonarr_series_title from Sonarr"
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

# If episode id exsits, then unmonitor episode from Sonarr.
if [[ -n $sonarr_episodefile_episodeids ]]; then
  unmonitor_episode
else
  log "No episodes IDs"
fi

exit 0
