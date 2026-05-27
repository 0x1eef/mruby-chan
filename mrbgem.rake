# frozen_string_literal: true

MRuby::Gem::Specification.new("mruby-chan") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef"
  spec.version = "0.1.0"
  spec.description = "InterProcess Communication (IPC) for mruby"

  spec.add_dependency "mruby-io", core: "mruby-io"
  spec.add_dependency "mruby-dir", core: "mruby-dir"
  spec.add_dependency "mruby-time", core: "mruby-time"
  spec.add_dependency "mruby-struct", core: "mruby-struct"

  spec.rbfiles = Dir.glob("#{__dir__}/mrblib/**/*.rb").sort
  spec.objs = Dir.glob("#{__dir__}/src/**/*.c").map do |f|
    objfile(f.relative_path_from(__dir__).to_s.pathmap("#{build_dir}/%X"))
  end
end
