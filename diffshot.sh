#!/bin/sh

folder="diffshots"
rm -rf $folder
mkdir $folder

# Preserves whitespace. ¯\_(ツ)_/¯
IFS='%'
# Removes the first commit since you can't diff it
# Prints SHA on one line and commit message on another because hard to "split"
commits=$(git log --pretty=format:"%h%n%s" | tail -r | tail -n +2 | tail -r)
commitnum=1
linenum=0
while read commitline; do
  commitnum=$(($linenum / 2))
  if (( $linenum % 2 == 0 )); then
    hash="$commitline"
  else
    # Removes non-alphanumeric characters from commit message, downcases, adds dashes
    message=$(echo $commitline | tr "[:upper:]" "[:lower:]" | sed \
      -e "s/[^a-zA-Z0-9 \-]//g" \
      -e "s/ /-/g" \
      -e "s/-\{2,\}/-/g")
    # A = added, M = modified, R = removed
    diffiles=$(git diff --diff-filter=AMR --name-only "$hash~..$hash")
    echo "$hash: $commitline"
    while read filepath; do
      echo "    $filepath"
      # Removes non-alphanumeric characters from filename, adds dashes
      fileabbr=$(echo $filepath | sed \
        -e "s/[^a-zA-Z0-9]/-/g" \
        -e "s/-\{2,\}/-/g")
      imageout="$message.$fileabbr.png"
      printcmd=$(cat <<heredoc
convert \
-font         "Consolas" \
-pointsize    "16" \
-extent       "800" \
-quality      "0" \
-bordercolor  "#000000" \
-background   "#000000" \
-gravity      "SouthWest"
heredoc)
      # First row of each image is the SHA and commit message
      printcmd+=" -fill \"#ffffff\" label:\"$hash: $commitline \""
      # 
      diff="$(git diff --ignore-all-space --no-prefix "$hash~..$hash" -- $filepath | tail -n +4)"
      while read diffline; do
        # If line begins with @@ or ---
        if [[ "$diffline" =~ ^(@@|---) ]]; then
          color="#aaaaaa"
        # If line begins with -
        elif [[ "$diffline" =~ ^-{1}([^-]|$) ]]; then
          color="#ff0000"
        # If line begins with +
        elif [[ "$diffline" =~ ^\+{1}([^\+]|$) ]]; then
          color="#00ff00"
        else
          color="#ffffff"
        fi
        # %q escapes quotes
        diffline=$(printf "%q" "$diffline")
        # Adds 20px to end of image and fills it with text
        printcmd+=" -splice 0x20 -fill \"$color\" -annotate 0 \" $diffline\""
      done <<< "$diff"
      # End with a blank line
      printcmd+=" -splice 0x20 -annotate 0 \" \""
      # Print to this filename
      printcmd+=" \"./$folder/$imageout\""
      eval $printcmd
    done <<< "$diffiles"
  fi
  let "linenum += 1"
done <<< "$commits"
unset IFS
