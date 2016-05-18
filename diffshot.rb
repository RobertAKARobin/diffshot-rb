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
      output.push({hash: hash, message: line})
    end
  end
  return output
end

puts all_commits
