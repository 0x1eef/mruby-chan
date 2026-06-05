# frozen_string_literal: true

describe "Chan::Pipe" do
  let(:pipe) { chan(Chan::Pure) }

  describe "#send" do
    it "writes data to the pipe and tracks bytes" do
      len = pipe.write("hello")
      assert_equal 5, len
      assert_equal 5, pipe.bytes_written
    end

    it "supports sending empty strings" do
      pipe.write("")
      assert_equal 0, pipe.bytes_written
    end

    it "supports sending multiple messages" do
      pipe.write("a")
      pipe.write("b")
      assert_equal 2, pipe.bytes_written
    end
  end

  describe "#recv" do
    it "reads data that was sent through the pipe" do
      pipe.write("hello")
      assert_equal "hello", pipe.read
    end

    it "reads messages in order" do
      pipe.write("first")
      pipe.write("second")
      assert_equal "first", pipe.read
      assert_equal "second", pipe.read
    end

    it "raises when reading from an empty pipe" do
      pipe.write("a")
      pipe.read
      assert_raises(Chan::WaitReadable) { pipe.read }
    end
  end

  describe "#empty?" do
    it "returns true when the pipe is empty" do
      assert pipe.empty?
    end

    it "returns false when the pipe has data" do
      pipe.write("data")
      refute pipe.empty?
    end
  end

  describe "#size" do
    it "returns the number of objects in the pipe" do
      assert_equal 0, pipe.size
      pipe.write("a")
      assert_equal 1, pipe.size
      pipe.write("b")
      assert_equal 2, pipe.size
    end

    it "decreases after reading" do
      pipe.write("a")
      pipe.read
      assert_equal 0, pipe.size
    end
  end

  describe "#close" do
    it "closes the pipe ends" do
      pipe.close
      assert pipe.closed?
    end

    it "removes temporary files" do
      pipe.close
      assert pipe.closed?
    end

    it "raises IOError when sending to a closed pipe" do
      pipe.close
      assert_raises(IOError) { pipe.write("data") }
    end
  end

  describe "#bytes_sent" do
    it "tracks total bytes written" do
      pipe.write("hello")
      pipe.write("world")
      assert_equal 10, pipe.bytes_sent
    end
  end

  describe "#bytes_received" do
    it "tracks total bytes read" do
      pipe.write("hello")
      pipe.read
      assert_equal 5, pipe.bytes_received
    end
  end
end

Minitest.run(ARGV) || exit(1)
