require "mini_magick"
require "yaml"

c = YAML::load_file(File.join(__dir__, 'config.yml'))

def all_commits
  output    = []
  raw       = `git log --pretty=format:"%h%n%s"`.split("\n")
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

all_commits.each_with_index do |commit, index|
  puts "#{commit[:hash]}: #{commit[:message]}"
  changed_files(commit[:hash]).each do |filename|
    puts "    #{filename}"
  end
end
