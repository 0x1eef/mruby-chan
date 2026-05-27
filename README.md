## About

mruby-chan is an easy to use library for InterProcess Communication (IPC)
for mruby.

The library provides a channel that can help facilitate communication between
mruby processes who have a parent &lt;=&gt; child relationship.
A channel lock is provided by
[lockf(3)](https://man.freebsd.org/cgi/man.cgi?query=lockf&sektion=3)
and a file in `Chan.tmpdir` to protect against race conditions
that can happen when multiple processes access the same channel
at the same time.

## Features

* Minimalist Inter-Process Communication (IPC) for parent &lt;=&gt; child processes.
* Channel-based communication using `IO.pipe`.
* Support for raw string communication (`Chan::Pure`).
* Blocking (`#send`, `#recv`) operations.
* Built-in file-based locking ([lockf(3)](https://man.freebsd.org/cgi/man.cgi?query=lockf&sektion=3)) to prevent race conditions.
* Option to use a null lock for scenarios where locking is not needed.
* Access to underlying pipe ends for fine-grained control.
* FreeBSD, Mac, and Linux support.
* Good docs.

## Examples

### chan

The `chan` method creates a channel with a given serializer:

```ruby
ch = chan(Chan::Pure)
```

### Serialization

A channel that will communicate purely in strings (in other words:
without serialization) is available as `chan(Chan::Pure)`. Otherwise
a custom serializer can be passed &mdash; any object that implements `dump`
and `load`:

```ruby
ch = chan(Chan::Pure)
```

### Read operations

#### #recv

The `ch.recv` method performs a blocking read.
The example performs a read that blocks until
the parent process writes to the channel:

```ruby
ch = chan(Chan::Pure)
fork do
  print "Received: ", ch.recv, "\n"
end
sleep(1)
puts "Sending..."
ch.send("hello")
ch.close
Process.wait

## Received: hello
```

### Write operations

#### #send

The `ch.send` method performs a blocking write.
A write can block when a lock is held by another process:

```ruby
ch = chan(Chan::Pure)
fork do
  puts ch.recv
end
ch.send("hello from parent")
ch.close
Process.wait

## hello from parent
```

### Lock

#### File

The default lock for a channel is a file lock. The locking mechanism is
implemented with the
[lockf](https://man.freebsd.org/cgi/man.cgi?query=lockf&apropos=0&sektion=3&manpath=FreeBSD+14.2-RELEASE+and+Ports&arch=default&format=html)
function from the C standard library:

```ruby
ch = chan(Chan::Pure, lock: :file)
5.times.map do
  fork do
    ch.send("data")
  end
end.each { Process.wait(_1) }
```

#### Null

The null lock is the same as using no lock at all. The null lock is
implemented as a collection of no-op operations:

```ruby
ch = chan(Chan::Pure, lock: :null)
fork do
  ch.send("data")
end
Process.wait
```

### Pipe ends

Access to the underlying pipe ends is available through
`ch.r` (read end) and `ch.w` (write end):

```ruby
ch = chan(Chan::Pure)
puts "Read end: #{ch.r}"
puts "Write end: #{ch.w}"
```

## Documentation

A complete API reference is available at
[0x1eef.github.io/x/mruby-chan](https://0x1eef.github.io/x/mruby-chan)

## Install

Add to your mruby build config:

```ruby
conf.gem github: "0x1eef/mruby-chan", branch: "main"
```

## Sources

* [github.com/0x1eef](https://github.com/0x1eef/mruby-chan#readme)
* [git.home.network](http://git.home.network/0x1eef/mruby-chan)

## License

[BSD Zero Clause](https://choosealicense.com/licenses/0bsd/)
<br>
See [LICENSE](./LICENSE)
