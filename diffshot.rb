require "yaml"
require "fileutils"
require "shellwords"

COMMIT_RANGE = (ARGV[0] || "")

C = YAML::load_file(File.join(__dir__, 'config.yml'))

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
  remote.sub!('git@github.com:', 'https://www.github.com/')
  remote.sub!(/\.git$/, "")
  return remote
end

def changed_files(hash)
  # A = added, M = modified, R = removed
  filelist  = `git diff --diff-filter=AMR --numstat #{hash}~..#{hash}`.split("\n")
  output    = []
  filelist.each_with_index do |file, index|
    # A numstat entry beginning with `-` is binary
    next if file =~ /^-/
    # Diff file lines start with tabs
    output.push(file.sub(/^[0-9]{1,}\t[0-9]{1,}\t/, ""))
  end
  return output
end

def file_diff(hash, file)
  diff = `git diff --ignore-all-space --no-prefix --no-color "#{hash}~..#{hash}" -- #{file}`
  return diff
end

def color_of(line)
  # If line begins with @@ or ---
  if line =~ /^(@@|---|\+{3})/
    return C["color"]["hide"]
  # If line begins with -
  elsif line =~ /^-/
    return C["color"]["delete"]
  # If line begins with +
  elsif line =~ /^\+/
    return C["color"]["add"]
  else
    return C["color"]["normal"]
  end
end

def q(string)
  return "\"#{string}\""
end

FileUtils.rm_rf(C["file"]["img_dir"])
FileUtils.mkdir(C["file"]["img_dir"])

all_commits.each_with_index do |commit, index|
  puts "#{commit[:hash]}: #{commit[:message]}"
  next if index == 0
  changed_files(commit[:hash]).each do |filename|
    puts "    #{filename}"
    imgname = "#{commit[:hash]}-#{filename}.png"
    lines   = []
    command = []
    command.concat [
      "convert",
      "-font",       q(C["font"]["family"]),
      "-pointsize",  q(C["font"]["size"]),
      "-extent",     q(C["image"]["width"]),
      "-quality",    q(C["image"]["quality"]),
      "-background", q(C["color"]["background"]),
      "-gravity",    q("SouthWest"),
      "-fill",       q(C["color"]["normal"]),
      "label:\" #{commit[:hash]}: #{commit[:message]}\""
    ]
    file_diff(commit[:hash], filename).split("\n").each do |line|
      command.concat [
        "-splice",     "0x#{C["font"]["height"]}",
        "-fill",       q(color_of(line)),
        "-annotate",   "0 #{q(" " + Shellwords.escape(line))}"
      ]
    end
    command.push q(File.join(__dir__, C["file"]["img_dir"], imgname))
    command = command.join(" ")
    system(command)
  end
end
