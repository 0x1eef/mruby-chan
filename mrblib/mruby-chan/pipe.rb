# frozen_string_literal: true

##
# {Chan::Pipe Chan::Pipe} is a channel that uses
# {IO.pipe} for InterProcess Communication. It
# provides a send/recv interface with optional
# file locking for synchronisation across processes.
#
# @example
#   ch = Chan::Pipe.new(Marshal)
#   ch.send([1, 2, 3])
#   ch.recv.pop # => 3
#   ch.close
class Chan::Pipe
  ##
  # @return [IO]
  #  Returns the read end of the pipe
  attr_reader :r

  ##
  # @return [IO]
  #  Returns the write end of the pipe
  attr_reader :w

  ##
  # @param [#dump, #load] serializer
  #  An object that implements `dump` and `load`
  # @param [String] tmpdir
  #  Directory where temporary files can be stored
  # @param [Symbol, Chan::NullLock, Chan::Lockf] lock
  #  The name of a lock (`:null` or `:file`), or a lock object
  # @return [Chan::Pipe]
  def initialize(serializer, tmpdir: Dir.tmpdir, lock: :null)
    @s = serializer
    @r, @w = IO.pipe
    @bytes_path = tmpfile_path(tmpdir, "bytes")
    @counter_path = tmpfile_path(tmpdir, "counter")
    @lock_path = tmpfile_path(tmpdir, "lock")
    @bytes = Bytes.new(@bytes_path)
    @counter = Counter.new(@counter_path)
    @lock = init_lock(lock)
  end

  ##
  # @return [Boolean]
  #  Returns true when the channel is closed
  def closed?
    @r.closed? && @w.closed?
  end

  ##
  # Closes the channel and removes temporary files
  # @raise [IOError]
  #  When the channel is already closed
  # @return [void]
  def close
    @lock.lock
    raise IOError, "closed channel" if closed?
    [@r, @w, @bytes, @counter].each(&:close)
    [@bytes_path, @counter_path, @lock_path].each { |p| File.unlink(p) rescue nil }
  rescue IOError
    @lock.release
    raise
  end

  ##
  # @group Write methods

  ##
  # Performs a blocking write
  # @param [Object] object
  #  An object to serialise and send
  # @raise [IOError]
  #  When the channel is closed
  # @return [Integer]
  #  Returns the number of bytes written to the channel
  def send(object)
    send_nonblock(object)
  rescue ::IO::WaitWritable
    wait_writable
    retry
  end
  alias_method :write, :send

  ##
  # Performs a non-blocking write
  # @param [Object] object
  #  An object to serialise and send
  # @raise [IOError]
  #  When the channel is closed
  # @raise [IO::WaitWritable]
  #  When a write to {#w} blocks
  # @return [Integer]
  #  Returns the number of bytes written to the channel
  def send_nonblock(object)
    @lock.lock_nonblock
    raise IOError, "closed channel" if closed?
    data = serialize(object)
    len = @w.write_nonblock(data)
    @bytes.push(len)
    @counter.increment!(bytes_written: len)
    len
  rescue ::IO::WaitWritable => ex
    @lock.release
    raise ::IO::WaitWritable, ex.message
  ensure
    @lock.release rescue nil
  end
  alias_method :write_nonblock, :send_nonblock

  ##
  # @endgroup

  ##
  # @group Read methods

  ##
  # Performs a blocking read
  # @raise [IOError]
  #  When the channel is closed
  # @return [Object]
  #  Returns a deserialised object from the channel
  def recv
    recv_nonblock
  rescue ::IO::WaitReadable
    wait_readable
    retry
  end
  alias_method :read, :recv

  ##
  # Performs a non-blocking read
  # @raise [IOError]
  #  When the channel is closed
  # @raise [IO::WaitReadable]
  #  When a read from {#r} blocks
  # @return [Object]
  #  Returns a deserialised object from the channel
  def recv_nonblock
    @lock.lock_nonblock
    raise IOError, "closed channel" if closed?
    len = @bytes.shift
    data = @r.read_nonblock(len)
    @counter.increment!(bytes_read: len)
    deserialize(data)
  rescue ::IO::WaitReadable => ex
    @lock.release
    raise ::IO::WaitReadable, ex.message
  end
  alias_method :read_nonblock, :recv_nonblock

  ##
  # @endgroup

  ##
  # @group Wait methods

  ##
  # Waits for the channel to become readable
  # @param [Float, Integer, nil] timeout
  #  The number of seconds to wait before timeout.
  #  Waits indefinitely with no arguments
  # @return [Chan::Pipe, nil]
  #  Returns self when the channel is readable, otherwise returns nil
  def wait_readable(timeout = nil)
    @r.wait_readable(timeout) and self
  end

  ##
  # Waits for the channel to become writable
  # @param [Float, Integer, nil] timeout
  #  The number of seconds to wait before timeout.
  #  Waits indefinitely with no arguments
  # @return [Chan::Pipe, nil]
  #  Returns self when the channel is writable, otherwise returns nil
  def wait_writable(timeout = nil)
    @w.wait_writable(timeout) and self
  end

  ##
  # @endgroup

  ##
  # @group Stat methods

  ##
  # @return [Boolean]
  #  Returns true when the channel is empty
  def empty?
    return true if closed?
    size.zero?
  end

  ##
  # @return [Integer]
  #  Returns the number of objects waiting to be read
  def size
    @bytes.size
  end

  ##
  # @return [Integer]
  #  Returns the total number of bytes written to the channel
  def bytes_sent
    @counter.bytes_written
  end
  alias_method :bytes_written, :bytes_sent

  ##
  # @return [Integer]
  #  Returns the total number of bytes read from the channel
  def bytes_received
    @counter.bytes_read
  end
  alias_method :bytes_read, :bytes_received

  ##
  # @endgroup

  private

  def init_lock(lock)
    case lock
    when :null then NullLock
    when :file then Lockf.new(File.open(@lock_path, File::RDWR | File::CREAT))
    else lock
    end
  end

  def tmpfile_path(tmpdir, prefix)
    "#{tmpdir}/#{prefix}_#{Time.now.to_f}_#{rand(9999)}"
  end

  def serialize(obj)
    @s.dump(obj)
  end

  def deserialize(str)
    @s.load(str)
  end
end
