# frozen_string_literal: true

##
# {Chan::NullLock Chan::NullLock} is a no-op lock
# that can be used instead of a file lock when
# locking is not needed.
class Chan::NullLock
  ##
  # @return [void]
  #  This method is a no-op
  def self.lock; end

  ##
  # @return [void]
  #  This method is a no-op
  def self.lock_nonblock; end

  ##
  # @return [void]
  #  This method is a no-op
  def self.release; end

  ##
  # @return [void]
  #  This method is a no-op
  def self.close; end

  ##
  # @return [true]
  #  Always returns true
  def self.lockable?; true; end
end
