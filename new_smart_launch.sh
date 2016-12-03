#!/bin/bash
echo '      ___         ___           ___                       ___           ___                       ___     '
echo '     /  /\       /  /\         /  /\          ___        /  /\         /  /\        ___          /  /\    '
echo '    /  /:/_     /  /::\       /  /:/         /  /\      /  /::\       /  /::\      /  /\        /  /::\   '
echo '   /  /:/ /\   /  /:/\:\     /  /:/         /  /:/     /  /:/\:\     /  /:/\:\    /  /:/       /  /:/\:\  '
echo '  /  /:/ /:/  /  /:/~/::\   /  /:/  ___    /  /:/     /  /:/  \:\   /  /:/~/:/   /__/::\      /  /:/  \:\ '
echo ' /__/:/ /:/  /__/:/ /:/\:\ /__/:/  /  /\  /  /::\    /__/:/ \__\:\ /__/:/ /:/___ \__\/\:\__  /__/:/ \__\:\'
echo ' \  \:\/:/   \  \:\/:/__\/ \  \:\ /  /:/ /__/:/\:\   \  \:\ /  /:/ \  \:\/:::::/    \  \:\/\ \  \:\ /  /:/'
echo '  \  \::/     \  \::/       \  \:\  /:/  \__\/  \:\   \  \:\  /:/   \  \::/~~~~      \__\::/  \  \:\  /:/ '
echo '   \  \:\      \  \:\        \  \:\/:/        \  \:\   \  \:\/:/     \  \:\          /__/:/    \  \:\/:/  '
echo '    \  \:\      \  \:\        \  \::/          \__\/    \  \::/       \  \:\         \__\/      \  \::/   '
echo '     \__\/       \__\/         \__\/                     \__\/         \__\/                     \__\/    '
# Checking if server is ready 
if [ $FACTORIO_WAITING == true ] 
then 
  until [ -f /opt/factorio/saves/ready ] 
  do 
    echo "# Waiting for backup daemon to be ready" 
    sleep 1 
  done 
fi
# Setting initial command
factorio_command="/opt/factorio/bin/x64/factorio"
# Include server-settings.json if one or more variables are populated
# removed FACTORIO_USER_TOKEN condition cause of bug (https://github.com/zopanix/docker_factorio_server/issues/23)
if [ "$FACTORIO_SERVER_NAME" ] \
|| [ "$FACTORIO_SERVER_DESCRIPTION" ] \
|| [ "$FACTORIO_SERVER_MAX_PLAYERS" ] \
|| [ "$FACTORIO_SERVER_VISIBILITY_PUBLIC" ] \
|| [ "$FACTORIO_SERVER_VISIBILITY_LAN" ] \
|| [ "$FACTORIO_USER_USERNAME" ] \
|| [ "$FACTORIO_USER_PASSWORD" ] \
|| [ "$FACTORIO_USER_TOKEN" ] \
|| [ "$FACTORIO_SERVER_GAME_PASSWORD" ] \
|| [ "$FACTORIO_SERVER_ALLOW_COMMANDS" ] \
|| [ "$FACTORIO_SERVER_ADMINS" ] \
|| [ "$FACTORIO_SERVER_VERIFY_IDENTITY" ]
then
  factorio_command="$factorio_command --server-settings /opt/factorio/server-settings.json"
  # Set Server Name default value if not set by user param
  if [ -z $FACTORIO_SERVER_NAME ]
  then
    FACTORIO_SERVER_NAME="Factorio Server $VERSION"
  fi
  # Set Visibility default value if not set by user param
  if [ -z $FACTORIO_SERVER_VISIBILITY_PUBLIC ]
  then
    FACTORIO_SERVER_VISIBILITY_PUBLIC="false"
  fi
  # Set Verify User Identity default value if not set by user param
  if [ -z $FACTORIO_SERVER_VERIFY_IDENTITY ]
  then
    FACTORIO_SERVER_VERIFY_IDENTITY="false"
  fi
  # Check for supplied credentials if visibility is set to public
  if [ $FACTORIO_SERVER_VISIBILITY_PUBLIC ]
  then
    if [ -z $FACTORIO_USER_USERNAME ]
    then
      echo "###"
      echo "# Server Visibility is set to public but no factorio.com Username is supplied!"
      echo "# Append: --env FACTORIO_USER_USERNAME=[USERNAME]"
      echo "# Defaulting back to Server Visibility: hidden"
      echo "###"
      FACTORIO_SERVER_VISIBILITY_PUBLIC="false"
    fi
    if [ "$FACTORIO_USER_USERNAME" ]
    then
#      if [ -z $FACTORIO_USER_PASSWORD ] && [ -z $FACTORIO_USER_TOKEN ]
      if [ -z $FACTORIO_USER_PASSWORD ]
      then
      echo "###"
#      echo "# Server Visibility is set to public but neither factorio.com Password or Token is supplied!"
      echo "# Server Visibility is set to public but neither factorio.com Password is supplied!"
      echo "# Append: --env FACTORIO_USER_PASSWORD=[PASSWORD]"
#      echo "# or --env FACTORIO_USER_TOKEN=[TOKEN]"
      echo "# Defaulting back to Server Visibility: hidden"
      echo "###"
      FACTORIO_SERVER_VISIBILITY_PUBLIC="false"
      fi
    fi
  fi
fi
# Populate server-settings.json
SERVER_SETTINGS=/opt/factorio/server-settings.json
cat << EOF > $SERVER_SETTINGS
{
  "name": "$FACTORIO_SERVER_NAME",
  "description": "$FACTORIO_SERVER_DESCRIPTION",
  "tags": [],

  "_comment_max_players": "Maximum number of players allowed, admins can join even a full server. 0 means unlimited.",
  "max_players": "$FACTORIO_SERVER_MAX_PLAYERS",

  "_comment_visibility": ["public: Game will be published on the official Factorio matching server",
                          "lan: Game will be broadcast on LAN"],
  "visibility":
  {
    "public": $FACTORIO_SERVER_VISIBILITY_PUBLIC,
    "lan": $FACTORIO_SERVER_VISIBILITY_LAN
  },

  "_comment_credentials": "Your factorio.com login credentials. Required for games with visibility public",
  "username": "$FACTORIO_USER_USERNAME",
  "password": "$FACTORIO_USER_PASSWORD",

  "_comment_token": "Authentication token. May be used instead of 'password' above.",
  "token": "$FACTORIO_USER_TOKEN",

  "game_password": "$FACTORIO_SERVER_GAME_PASSWORD",

  "_comment_require_user_verification": "When set to true, the server will only allow clients that have a valid Factorio.com account",
  "require_user_verification": $FACTORIO_SERVER_VERIFY_IDENTITY,

  "_comment_max_upload_in_kilobytes_per_second" : "optional, default value is 0. 0 means unlimited.",
  "max_upload_in_kilobytes_per_second": 0,

  "_comment_minimum_latency_in_ticks": "optional one tick is 16ms in default speed, default value is 0. 0 means no minimum.",
  "minimum_latency_in_ticks": 0,

  "_comment_ignore_player_limit_for_returning_players": "Players that played on this map already can join even when the max player limit was reached.",
  "ignore_player_limit_for_returning_players": false,

  "_comment_allow_commands": "possible values are, true, false and admins-only",
  "allow_commands": "$FACTORIO_SERVER_ALLOW_COMMANDS",

  "_comment_autosave_interval": "Autosave interval in minutes",
  "autosave_interval": $FACTORIO_AUTOSAVE_INTERVAL,

  "_comment_autosave_slots": "server autosave slots, it is cycled through when the server autosaves.",
  "autosave_slots": $FACTORIO_AUTOSAVE_SLOTS,

  "_comment_afk_autokick_interval": "How many minutes until someone is kicked when doing nothing, 0 for never.",
  "afk_autokick_interval": 0,

  "_comment_auto_pause": "Whether should the server be paused when no players are present.",
  "auto_pause": $FACTORIO_AUTO_PAUSE,

  "only_admins_can_pause_the_game": true,

  "_comment_autosave_only_on_server": "Whether autosaves should be saved only on server or also on all connected clients. Default is true.",
  "autosave_only_on_server": true,

  "_comment_admins": "List of case insensitive usernames, that will be promoted immediately",
  "admins": $FACTORIO_SERVER_ADMINS
}
EOF

echo "Generated server-settings.json file:"
echo
cat $SERVER_SETTINGS

# Setting heavy mode option
if [ "$FACTORIO_MODE" == "heavy" ]
then
factorio_command="$factorio_command --heavy"
fi
# Setting complete mode option
if [ "$FACTORIO_MODE" == "complete" ]
then
factorio_command="$factorio_command --complete"
fi
# Setting rcon-port option
factorio_command="$factorio_command --rcon-port 27015"
# Setting rcon password option
if [ -z $FACTORIO_RCON_PASSWORD ]
then
  FACTORIO_RCON_PASSWORD=$(cat /dev/urandom | tr -dc 'a-f0-9' | head -c16)
  echo "###"
  echo "# RCON password is '$FACTORIO_RCON_PASSWORD'"
  echo "###"
fi
factorio_command="$factorio_command --rcon-password $FACTORIO_RCON_PASSWORD"

# TODO Adding this because of bug, will need to be removed once bug in factorio is fixed
cd /opt/factorio/saves
# Handling save settings
save_dir="/opt/factorio/saves"
if [ -z $FACTORIO_SAVE ]
then
  if [ "$(ls -A $save_dir)" ]
  then
    echo "###"
    echo "# Taking latest save"
    echo "###"
  else
    echo "###"
    echo "# Creating a new map [save.zip]"
    echo "###"
    /opt/factorio/bin/x64/factorio --create save.zip
  fi
  factorio_command="$factorio_command --start-server-load-latest"
else
  factorio_command="$factorio_command --start-server $FACTORIO_SAVE"
fi
echo "###"
echo "# Launching Game"
echo "###"
# Closing stdin
exec 0<&-
exec $factorio_command
