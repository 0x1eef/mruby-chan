module Chan
  class Lockf
    def initialize(fd)
      @fd = fd
    end

    def lock(len = 0)
      Chan.lockf(@fd, Chan::F_LOCK, len)
    end

    def lock_nonblock(len = 0)
      Chan.lockf_nonblock(@fd, Chan::F_TLOCK, len)
    end

    def release(len = 0)
      Chan.lockf(@fd, Chan::F_ULOCK, len)
    end

    def close
      release
    end

    def lockable?(len = 0)
      Chan.lockf_nonblock(@fd, Chan::F_TEST, len)
    rescue
      false
    end
  end
end
