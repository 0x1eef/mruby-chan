# frozen_string_literal: true

##
# {Chan::Pipe Chan::Pipe} is a channel that uses
# {IO.pipe} for InterProcess Communication. It
# provides a send/recv interface with optional
# file locking for synchronisation across processes.
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
  def initialize(serializer, tmpdir: Chan.tmpdir, lock: :null)
    @s = Chan.serializers[serializer]&.call || serializer
    @r, @w = IO.pipe
    @bytes_path = tmpfile_path(tmpdir, "bytes")
    @counter_path = tmpfile_path(tmpdir, "counter")
    @lock_path = tmpfile_path(tmpdir, "lock")
    @bytes = Chan::Bytes.new(@bytes_path)
    @counter = Chan::Counter.new(@counter_path)
    @lock = init_lock(lock)
  end

  ##
  # @return [Boolean] true when the channel is closed
  def closed?
    @r.closed? && @w.closed?
  end

  ##
  # Closes the channel and removes temporary files
  # @raise [IOError] when the channel is already closed
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
  # Performs a blocking write by default. When nonblocking mode
  # has been enabled with {#nonblock!}, raises {Chan::WaitWritable}
  # if the write would block.
  # @param [Object] object to serialise and send
  # @raise [IOError] when the channel is closed
  # @raise [Chan::WaitWritable] when the nonblocking write would block
  # @return [Integer] number of bytes written
  def write(object)
    raise IOError, "closed channel" if closed?
    @lock.lock_nonblock
    data = @write_data || serialize(object)
    len = @write_len || data.bytesize
    @write_offset ||= 0
    if @write_data.nil?
      @write_data, @write_len, @write_offset = data, len, 0
      @bytes.push(len)
    end
    while @write_offset < @write_len
      @write_offset += @w.syswrite(
        @write_data[@write_offset, @write_len - @write_offset]
      )
    end
    @counter.increment!(bytes_written: len)
    @write_data, @write_len, @write_offset = nil, nil, nil
    len.tap { @lock.release }
  rescue Errno::EAGAIN
    raise Chan::WaitWritable
  ensure
    @lock.release
  end

  ##
  # @endgroup

  ##
  # @group Read methods

  ##
  # Performs a blocking read by default. When nonblocking mode
  # has been enabled with {#nonblock!}, raises {Chan::WaitReadable}
  # if the read would block.
  # @raise [IOError] when the channel is closed
  # @raise [Chan::WaitReadable] when the nonblocking read would block
  # @return [Object] deserialised object from the channel
  def read
    raise IOError, "closed channel" if closed?
    @lock.lock_nonblock
    len = @read_len || @bytes.shift
    if len.zero?
      raise Chan::WaitReadable, "read would block"
    elsif @read_len.nil?
      @read_len, @read_data = len, +""
    end
    while @read_data.bytesize < @read_len
      @read_data << @r.sysread(@read_len - @read_data.bytesize)
    end
    @counter.increment!(bytes_read: @read_len)
    data = @read_data
    @read_len, @read_data = nil, nil
    deserialize(data).tap { @lock.release }
  rescue Errno::EAGAIN
    raise Chan::WaitReadable, "read would block"
  ensure
    @lock.release
  end

  ##
  # @endgroup

  # @!group Mode methods
  # @!method nonblock!
  #  Enables nonblocking mode on both pipe ends.
  #
  #  After enabling nonblocking mode, {#read} raises {Chan::WaitReadable}
  #  and {#write} raises {Chan::WaitWritable} when the operation cannot
  #  complete immediately.
  #  @return [nil]
  # @!endgroup

  ##
  # @group Stat methods

  ##
  # @return [Boolean] true when the channel is empty
  def empty?
    return true if closed?
    size.zero?
  end

  ##
  # @return [Integer] number of objects waiting to be read
  def size
    @bytes.size
  end

  ##
  # @return [Integer] total bytes written to the channel
  def bytes_sent
    @counter.bytes_written
  end
  alias_method :bytes_written, :bytes_sent

  ##
  # @return [Integer] total bytes read from the channel
  def bytes_received
    @counter.bytes_read
  end
  alias_method :bytes_read, :bytes_received

  ##
  # @endgroup

  private

  def init_lock(lock)
    case lock
    when :null then Chan::NullLock
    when :file then Chan::Lockf.new(File.open(@lock_path, File::RDWR | File::CREAT))
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
