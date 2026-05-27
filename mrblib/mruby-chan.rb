module Chan
end

module Kernel
  def xchan(serializer, tmpdir: Dir.tmpdir, lock: :null)
    Chan::Pipe.new(serializer, tmpdir: tmpdir, lock: lock)
  end
end
