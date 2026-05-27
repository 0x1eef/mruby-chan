  def initialize(serializer, tmpdir: Chan.tmpdir, lock: :null)
    @s = Chan.serializers[serializer]&.call || serializer
    @r, @w = IO.pipe
    @bytes_path = tmpfile_path(tmpdir, "bytes")
    @counter_path = tmpfile_path(tmpdir, "counter")
    @lock_path = tmpfile_path(tmpdir, "lock")
    @bytes = Bytes.new(@bytes_path)
    @counter = Counter.new(@counter_path)
    @lock = init_lock(lock)
  end
