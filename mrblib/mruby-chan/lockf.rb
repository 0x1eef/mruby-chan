# frozen_string_literal: true

##
# {Chan::Lockf Chan::Lockf} is a wrapper around
# the POSIX lockf() function, exposed through
# {Chan.lockf} and {Chan.lockf_nonblock}.
class Chan::Lockf
  ##
  # @param [Integer] fd
  #  An open file descriptor
  # @return [Chan::Lockf]
  def initialize(fd)
    @io = fd if fd.respond_to?(:fileno)
    @fd = @io ? @io.fileno : fd
  end

  ##
  # Acquire an exclusive lock, blocking until
  # the lock becomes available
  # @param [Integer] len
  #  The number of bytes to lock (0 means the entire file)
  # @return [void]
  def lock(len = 0)
    Chan.lockf(@fd, Chan::F_LOCK, len)
  end

  ##
  # Acquire an exclusive lock without blocking
  # @param [Integer] len
  #  The number of bytes to lock
  # @return [Boolean]
  def lock_nonblock(len = 0)
    Chan.lockf_nonblock(@fd, Chan::F_TLOCK, len)
  end

  ##
  # Release a lock
  # @param [Integer] len
  #  The number of bytes to unlock
  # @return [void]
  def release(len = 0)
    Chan.lockf(@fd, Chan::F_ULOCK, len)
  end

  ##
  # Release the lock and close the underlying fd
  # @return [void]
  def close
    release
  end

  ##
  # Test whether a lock can be acquired without blocking
  # @param [Integer] len
  #  The number of bytes to test
  # @return [Boolean]
  def lockable?(len = 0)
    Chan.lockf_nonblock(@fd, Chan::F_TEST, len)
  rescue
    false
  end
end
