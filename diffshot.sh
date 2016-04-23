#!/bin/sh

IMG_DIRECTORY="diffshots"

FONT="Consolas"
FONT_SIZE="16"
LINE_HEIGHT="20"

COLOR_HIDE="#aaaaaa"
COLOR_DELETE="#ff0000"
COLOR_ADD="#00ff00"
COLOR_NORMAL="#ffffff"
COLOR_BACKGROUND="#000000"

IMG_WIDTH="800"
IMG_QUALITY="0"

PRINT_COMMAND=$(cat <<heredoc
convert \
-font         "$FONT" \
-pointsize    "$FONT_SIZE" \
-extent       "$IMG_WIDTH" \
-quality      "$IMG_QUALITY" \
-background   "$COLOR_BACKGROUND" \
-gravity      "SouthWest"
heredoc)

determine_line_color(){
  # If line begins with @@ or ---
  if [[ "$1" =~ ^(@@|---) ]]; then
    echo $COLOR_HIDE
  # If line begins with -
  elif [[ "$1" =~ ^- ]]; then
    echo $COLOR_DELETE
  # If line begins with +
  elif [[ "$1" =~ ^\+ ]]; then
    echo $COLOR_ADD
  else
    echo $COLOR_NORMAL
  fi
  return 0
}

# Removes the first commit since you can't diff it
# Prints SHA on one line and commit message on another because hard to "split"
git_all_commits_but_first(){
  git log --pretty=format:"%h%n%s" | tail -r | tail -n +2 | tail -r
}

git_list_of_changed_files(){
  hash=$1
  # A = added, M = modified, R = removed
  git diff --diff-filter=AMR --name-only "$hash~..$hash"
}

git_file_diff(){
  hash=$1
  file=$2
  git diff --ignore-all-space --no-prefix "$hash~..$hash" -- $file| tail -n +4
}

english_to_spine_case(){
  # Removes non-alphanumeric characters from commit message, downcases, adds dashes
  echo $1| tr "[:upper:]" "[:lower:]" | sed \
    -e "s/[^a-zA-Z0-9 \-]//g" \
    -e "s/ /-/g" \
    -e "s/-\{2,\}/-/g"
}

filename_to_spine_case(){
  # Removes non-alphanumeric characters from filename, adds dashes
  echo $1 | sed \
    -e "s/[^a-zA-Z0-9]/-/g" \
    -e "s/-\{2,\}/-/g"
}

properly_escaped(){
  printf "%q" "$1" | LANG=C sed -e s/%/\\\\%/g
}

rm -rf $IMG_DIRECTORY
mkdir $IMG_DIRECTORY

linenum=0
IFS=$'\n'
for commitline in $(git_all_commits_but_first); do
  (( linenum++ ))
  if (( $linenum % 2 != 0 )); then
    hash=$commitline
  else
    echo "$hash: $commitline"
    message=$(english_to_spine_case $commitline)
    for filepath in $(git_list_of_changed_files $hash); do
      echo "    $filepath"
      fileabbr=$(filename_to_spine_case $filepath)
      imageout="$message.$fileabbr.png"
      IMAGE_GEN_COMMAND=$PRINT_COMMAND
      IMAGE_GEN_COMMAND+=" -fill \"$COLOR_NORMAL\" label:\"$hash: $commitline \""
      for diffline in $(git_file_diff $hash $filepath); do
        diffline=$(properly_escaped $diffline)
        rowcolor=$(determine_line_color $diffline)
        IMAGE_GEN_COMMAND+=" -splice 0x$LINE_HEIGHT -fill \"$rowcolor\" -annotate 0 \" $diffline\""
      done
      IMAGE_GEN_COMMAND+=" -splice 0x$LINE_HEIGHT -annotate 0 \" \""
      IMAGE_GEN_COMMAND+=" \"./$IMG_DIRECTORY/$imageout\""
      eval $IMAGE_GEN_COMMAND
    done
  fi
done
unset IFS
