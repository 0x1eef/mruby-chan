# frozen_string_literal: true

##
# @author 0x1eef
# @since 0.1.0
# @example
#   ch = chan(Chan::Pure)
#   ch.write("hello")
#   ch.read # => "hello"
#   ch.close
module Chan
  ##
  # @return [SystemCallError]
  WaitReadable = Class.new(Errno::EWOULDBLOCK)

  ##
  # @return [SystemCallError]
  WaitWritable = Class.new(Errno::EWOULDBLOCK)

  ##
  # Coerces an object to a string for a
  # channel communicating in raw strings
  Pure = Class.new do
    def self.dump(str) = str.to_s
    def self.load(str) = str.to_s
  end

  ##
  # @return [Hash<Symbol, Proc>]
  #  Returns the default serializers
  def self.serializers
    {
      pure: lambda { Pure },
      json: lambda { JSON }
    }
  end

  ##
  # @return [String]
  #  Returns a path suitable for temporary files
  def self.tmpdir
    ENV["TMPDIR"] || ENV["TMP"] || "/tmp"
  end
end

module Kernel
  ##
  # @example
  #   ch = chan(Chan::Pure)
  #   ch.write("hello")
  #   ch.read # => "hello"
  #   ch.close
  # @param [#dump, #load] serializer
  #  An object that implements `dump` and `load`
  # @param [String] tmpdir
  #  Directory where temporary files can be stored
  # @param [Symbol, Chan::NullLock, Chan::Lockf] lock
  #  The name of a lock (`:null` or `:file`), or a lock object
  # @return [Chan::Pipe]
  def chan(serializer, tmpdir: Chan.tmpdir, lock: :null)
    Chan::Pipe.new(serializer, tmpdir: tmpdir, lock: lock)
  end
end
