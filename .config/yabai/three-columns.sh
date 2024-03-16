windows=$(yabai -m query --windows --display 1 | jq '[.[] | select(."is-visible"==true and ."is-floating"==false)] | length')
resolution=$(system_profiler SPDisplaysDataType | awk '/Resolution/{print $2, $3, $4}')

if [[ $resolution == "3024 x 1964" ]]; then
  yabai -m config left_padding 15
  yabai -m config right_padding 15
  yabai -m space --balance
else
  if [[ $windows == 1 ]]; then
    yabai -m config left_padding 1400
    yabai -m config right_padding 1400
    yabai -m space --balance
  elif [[ $windows == 2 ]]; then
    yabai -m config left_padding 849
    yabai -m config right_padding 849
    yabai -m space --balance
  elif [[ $windows == 3 ]]; then
    yabai -m config left_padding 15
    yabai -m config right_padding 15
    yabai -m space --balance
  fi
fi
