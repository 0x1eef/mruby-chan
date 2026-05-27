# frozen_string_literal: true

##
# @author 0x1eef
# @since 0.1.0
# @example
#   ch = xchan(Marshal)
#   ch.send([1, 2, 3])
#   ch.recv.pop # => 3
#   ch.close
module Chan
end

module Kernel
  ##
  # @example
  #   ch = xchan(Marshal)
  #   ch.send([1,2,3])
  #   ch.recv.pop # => 3
  #   ch.close
  # @param [#dump, #load] serializer
  #  An object that implements `dump` and `load`
  # @param [String] tmpdir
  #  Directory where temporary files can be stored
  # @param [Symbol, Chan::NullLock, Chan::Lockf] lock
  #  The name of a lock (`:null` or `:file`), or a lock object
  # @return [Chan::Pipe]
  def xchan(serializer, tmpdir: Dir.tmpdir, lock: :null)
    Chan::Pipe.new(serializer, tmpdir: tmpdir, lock: lock)
  end
end
