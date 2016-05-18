require "mini_magick"
require "yaml"

c = YAML::load_file(File.join(__dir__, "config.yml"))

puts c.to_s