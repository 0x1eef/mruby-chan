# frozen_string_literal: true
load File.join(__dir__, "mrblib", "mruby-chan", "version.rb")

MRuby::Gem::Specification.new("mruby-chan") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef"
  spec.version = Chan::VERSION
  spec.description = "Easy IPC for mruby"

  spec.add_dependency "mruby-io", core: "mruby-io"
  spec.add_dependency "mruby-dir", core: "mruby-dir"
  spec.add_dependency "mruby-time", core: "mruby-time"
  spec.add_dependency "mruby-struct", core: "mruby-struct"

  spec.rbfiles = Dir.glob("#{__dir__}/mrblib/**/*.rb").sort
  spec.objs = Dir.glob("#{__dir__}/src/**/*.c").map do |f|
    objfile(f.relative_path_from(__dir__).to_s.pathmap("#{build_dir}/%X"))
  end
end
