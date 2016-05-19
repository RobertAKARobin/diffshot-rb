require "yaml"
require "fileutils"
require "shellwords"

COMMIT_RANGE = (ARGV[0] || "")

C = YAML::load_file(File.join(__dir__, "config.yml"))

def first_commit
  raw = `git rev-list --max-parents=0 HEAD`
  return raw[0..6]
end

def all_commits
  output    = []
  raw       = `git log --pretty=format:"%h%n%s" #{COMMIT_RANGE}`.split("\n")
  hash      = ""
  raw.each_with_index do |line, linenum|
    if linenum.even?
      hash  = line
    else
      output.unshift({hash: hash, message: line})
    end
  end
  return output
end

def github_url
  remote =`git remote get-url origin`
  remote.sub!("git@github.com:", "https://www.github.com/")
  remote.sub!(/\.git$/, "")
  return remote.strip
end

def all_files(hash)
  return `git show --pretty=format: --numstat #{hash}`
end

def changed_files(hash)
  # A = added, M = modified, R = removed
  return `git diff --diff-filter=AMR --numstat #{hash}~..#{hash}`
end

def file_list(filelist)
  output    = []
  filelist.split("\n").each_with_index do |file, index|
    # A numstat entry beginning with `-` is binary
    next if file =~ /^-/
    # Diff file lines start with tabs
    output.push(file.sub(/^[0-9]{1,}\t[0-9]{1,}\t/, ""))
  end
  return output
end

def file_diff(hash, file)
  diff = `git show --format=format: \
  --no-prefix \
  --no-color \
  --ignore-all-space \
  --ignore-space-change \
  --ignore-space-at-eol \
  --ignore-blank-lines \
  #{hash} -- #{file}`
  return diff
end

def color_of(line)
  if line =~ /^(@@|---|\+\+\+)/
    return C["color"]["hide"]
  elsif line =~ /^-/
    return C["color"]["delete"]
  elsif line =~ /^\+/
    return C["color"]["add"]
  else
    return C["color"]["normal"]
  end
end

def spine_case(string)
  output = string.downcase
  output.gsub!(/[^a-zA-Z0-9 \-]/, "")
  output.gsub!(/ /, "-")
  output.gsub!(/-{2,}/, "-")
  return output
end

def anchor(string)
  output = string.downcase
  output.gsub!(/ /, "-")
  output.gsub!(/[^a-zA-Z0-9\-_]/, "")
  return "##{output}"
end

def q(string)
  return "\"#{string}\""
end

def annotate(string, options = {})
  return [
    "-splice",     "0x#{options[:height] || C["font"]["height"]}",
    "-fill",       q(options[:color] || color_of(string)),
    # Necessary to escape `\n`. Sigh.
    "-annotate",   "0 #{q(" " + Shellwords.escape(string).gsub("\\\\", "\\\\\\\\\\\\\\\\"))}"
  ]
end

# =====
# MAIN PROCESS BEGINS
# =====

FileUtils.rm_rf(C["file"]["img_dir"])
FileUtils.mkdir(C["file"]["img_dir"])

cTABLE  = ""
cOMMITS = ""

all_commits.each_with_index do |commit, index|
  puts "#{commit[:hash]}: #{commit[:message]}"
  if index == 0 && commit[:hash] == first_commit
    filenames = all_files(commit[:hash])
  else
    filenames = changed_files(commit[:hash])
  end
  filenames   = file_list(filenames)

cTABLE += <<-____
- [#{commit[:hash]}: #{commit[:message]}](#{anchor commit[:message]})
____

cOMMITS += <<-____
# #{commit[:message]}
> [#{commit[:hash]}](#{github_url}/commit/#{commit[:hash]})

____

  filenames.each do |filename|
    puts "    #{filename}"
    header    = "#{commit[:message]}: \`#{filename}\`"
    imgname   = C["file"]["img_dir"] + "/" + [spine_case(commit[:message]), filename, "png"].join(".")
    
cTABLE  += <<-____
    - [#{filename}](#{anchor header})
____

cOMMITS += <<-____
### [#{header}](#{github_url}/blob/#{commit[:hash]}/#{filename})

![#{commit[:message]}, #{filename}](#{imgname})
____

    command   = [
      "convert",
      "-font",       q(C["font"]["family"]),
      "-pointsize",  q(C["font"]["size"]),
      "-extent",     q(C["image"]["width"]),
      "-quality",    q(C["image"]["quality"]),
      "-background", q(C["color"]["background"]),
      "-gravity",    q("SouthWest"),
      "-fill",       q(C["color"]["normal"]),
      "label:\" \""
    ]
    command.concat annotate("#{commit[:hash]}: #{commit[:message]}", {color: "#FFFF00", height: 8})
    file_diff(commit[:hash], filename).split("\n").each do |line|
      command.concat annotate(line)
    end
    command.concat annotate(" ", {height: 8})
    command.push q(File.join(__dir__, imgname))
    command = command.join(" ")
    system(command)
  end
end

File.write C["file"]["markdown"], <<-____
# #{github_url}

> This commit history created using [Diffshot](https://github.com/RobertAKARobin/diffshot)

## Table of Contents

#{cTABLE}

#{cOMMITS}
____
