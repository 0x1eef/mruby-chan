# frozen_string_literal: true

class Chan::Pipe
  attr_reader :r, :w

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

  def closed?
    @r.closed? && @w.closed?
  end

  def close
    @lock.lock
    raise IOError, "closed channel" if closed?
    [@r, @w, @bytes, @counter].each(&:close)
    [@bytes_path, @counter_path, @lock_path].each { |p| File.unlink(p) rescue nil }
  rescue IOError
    @lock.release
    raise
  end

  def send(object)
    send_nonblock(object)
  rescue ::IO::WaitWritable
    wait_writable
    retry
  end
  alias_method :write, :send

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

  def recv
    recv_nonblock
  rescue ::IO::WaitReadable
    wait_readable
    retry
  end
  alias_method :read, :recv

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

  def wait_readable(timeout = nil)
    @r.wait_readable(timeout) and self
  end

  def wait_writable(timeout = nil)
    @w.wait_writable(timeout) and self
  end

  def empty?
    return true if closed?
    size.zero?
  end

  def size
    @bytes.size
  end

  def bytes_sent
    @counter.bytes_written
  end
  alias_method :bytes_written, :bytes_sent

  def bytes_received
    @counter.bytes_read
  end
  alias_method :bytes_read, :bytes_received

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
