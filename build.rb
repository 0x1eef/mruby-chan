MRuby::Build.new("mruby-chan") do |conf|
  conf.toolchain

  conf.gembox "default"
  conf.gem core: "mruby-io"
  conf.gem core: "mruby-dir"
  conf.gem core: "mruby-time"
  conf.gem core: "mruby-struct"
  conf.gem File.expand_path(__dir__)

  case ENV["BUILD_PROFILE"] || "test"
  when "test", "developer"
    conf.enable_debug
  when "production"
    conf.cc.flags << "-DNDEBUG"
  else
    raise ArgumentError, "unknown BUILD_PROFILE=#{profile.inspect}"
  end
end
