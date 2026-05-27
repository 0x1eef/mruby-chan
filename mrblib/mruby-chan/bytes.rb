module Chan
  class Bytes
    def initialize(path)
      @io = File.open(path, File::RDWR | File::CREAT | File::TRUNC)
      @io.sync = true
      write(@io, [])
    end

    def unshift(len)
      return 0 if len.nil? || len.zero?
      bytes = read(@io)
      bytes.unshift(len)
      write(@io, bytes)
      len
    end

    def push(len)
      return 0 if len.nil? || len.zero?
      bytes = read(@io)
      bytes.push(len)
      write(@io, bytes)
      len
    end

    def shift
      bytes = read(@io)
      return 0 if bytes.size.zero?
      len = bytes.shift
      write(@io, bytes)
      len
    end

    def size
      read(@io).size
    end

    def close
      @io.close
    end

    private

    def read(io)
      deserialize(io.read).tap { io.rewind }
    end

    def write(io, bytes)
      io.rewind
      io.truncate(0)
      io.write(serialize(bytes))
      io.rewind
    end

    def serialize(bytes)
      bytes.pack("Q>*")
    end

    def deserialize(payload)
      payload.unpack("Q>*")
    end
  end
end
