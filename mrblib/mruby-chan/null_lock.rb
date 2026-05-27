module Chan
  class NullLock
    def self.lock; end
    def self.lock_nonblock; end
    def self.release; end
    def self.close; end
    def self.lockable?; true; end
  end
end
