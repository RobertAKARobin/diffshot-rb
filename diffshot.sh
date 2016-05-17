#!/bin/bash
LANG=C
IFS='
'

IMG_DIRECTORY="_DIFFSHOTS"
MARKDOWN_FILE="_DIFFSHOTS.md"

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

get_github_url(){
  gitpfx='git@github.com:'
  urlpfx='https://www.github.com/'
  echo $(git remote get-url origin | sed "s~$gitpfx~$urlpfx~" | sed "s~\.git\$~~")
}

GITHUB_URL="$(get_github_url)"

determine_line_color(){
  # If line begins with @@ or ---
  if [[ "$1" =~ ^(@@|---|\+\+\+) ]]; then
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
  git log --pretty=format:"%s%n%h" | tail -r | tail -n +2
}

git_list_of_changed_files(){
  hash=$1
  diffiles=""
  while read file; do
    # A numstat entry beginning with `-` is binary
    if [[ "$file" =~ ^[^-] ]]; then
      diffiles+="$(echo $file | sed -e $'s/^[0-9]\{1,\}\t[0-9]\{1,\}\t//')"
      diffiles+=$'\n'
    fi
    # A = added, M = modified, R = removed
  done <<< "$(git diff --diff-filter=AMR --numstat "$hash~..$hash")"
  echo "$diffiles"
}

git_file_diff(){
  hash=$1
  file=$2
  git diff --ignore-all-space --no-prefix "$hash~..$hash" -- $file | tail -n +4 | LANG=C sed -e s/\\\\/\\\\\\\\\\\\\\\\/g
  # Seriously, Bash?
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

gh_anchor(){
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -e s/\ /-/g | tr -cd '[a-zA-Z0-9-_]'
}

rm -rf $IMG_DIRECTORY
mkdir $IMG_DIRECTORY

INDEX=""
COMMITS=""

linenum=0
while read commitline; do
  (( linenum++ ))
  if (( $linenum % 2 != 0 )); then
    hash=$commitline
  else
    echo "$hash: $commitline"
    message=$(english_to_spine_case $commitline)
    COMMITS+="# $commitline\n\n"
    COMMITS+="> [$hash]($GITHUB_URL/commit/$hash)\n\n"
    INDEX+="- [$hash: $commitline](#$(gh_anchor $commitline))\n"
    while read filepath; do
      echo "    $filepath"
      header="$commitline: \`$filepath\`"
      COMMITS+="### [$header]($GITHUB_URL/blob/$hash/$filepath)\n"
      INDEX+="  - [$filepath](#$(gh_anchor $header))\n"
      fileabbr=$(filename_to_spine_case $filepath)
      imageout="$message.$fileabbr.png"
      IMAGE_GEN_COMMAND=$PRINT_COMMAND
      IMAGE_GEN_COMMAND+=" -fill \"$COLOR_NORMAL\" label:\"$hash: $commitline \""
      while read diffline; do
        diffline=$(properly_escaped $diffline)
        rowcolor=$(determine_line_color $diffline)
        IMAGE_GEN_COMMAND+=" -splice 0x$LINE_HEIGHT -fill \"$rowcolor\" -annotate 0 \" $diffline\""
      done <<< "$(git_file_diff $hash $filepath)"
      IMAGE_GEN_COMMAND+=" -splice 0x$LINE_HEIGHT -annotate 0 \" \""
      IMAGE_GEN_COMMAND+=" \"./$IMG_DIRECTORY/$imageout\""
      eval $(printf "%s%q\n\n" $IMAGE_GEN_COMMAND)
      COMMITS+="![$commitline, $filepath]($IMG_DIRECTORY/$imageout)\n\n"
    done <<< "$(git_list_of_changed_files $hash)"
  fi
done <<< "$(git_all_commits_but_first)"

printf "# $GITHUB_URL \n\
> This commit history created using [Diffshot](https://github.com/RobertAKARobin/diffshot)\n\n\

## Table of Contents
$INDEX
$COMMITS
" > $MARKDOWN_FILE

unset IFS
unset LANG
