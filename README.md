# Celluloid::JeroMQ
=================

Celluloid::JeroMQ is a fork of Celluloid::ZMQ which provides Celluloid actors
that can interact with [0MQ sockets][0mq].  Underneath, it's built on the
[jeromq][jeromq] library, which is a pure-Java implementation of zeromq.

[0mq]: http://www.zeromq.org/
[jeromq]: https://github.com/zeromq/jeromq
[dcell]: https://github.com/celluloid/dcell

It provides different `Celluloid::JeroMQ::Socket` classes which can be
initialized then sent `bind` or `connect`. Once bound or connected, the socket
can `read` or `send` depending on whether it's readable or writable.

## Supported Platforms

Celluloid::JeroMQ only works on JRuby in 1.9 mode.

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line option
to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment variable.

## 0MQ Socket Types

The following 0MQ socket types are supported (see [sockets.rb][socketsrb] for more info)

[socketsrb]: https://github.com/celluloid/celluloid-jeromq/blob/master/lib/celluloid/jeromq/sockets.rb

* ReqSocket / RepSocket
* PushSocket / PullSocket
* PubSocket / SubSocket

## Usage

```ruby
require 'celluloid/jeromq'

Celluloid::JeroMQ.init

class Server
  include Celluloid::JeroMQ

  def initialize(address)
    @socket = PullSocket.new

    begin
      @socket.bind(address)
    rescue IOError
      @socket.close
      raise
    end
  end

  def run
    loop { async.handle_message @socket.read }
  end

  def handle_message(message)
    puts "got message: #{message}"
  end
end

class Client
  include Celluloid::JeroMQ

  def initialize(address)
    @socket = PushSocket.new

    begin
      @socket.connect(address)
    rescue IOError
      @socket.close
      raise
    end
  end

  def write(message)
    @socket.send(message)

    nil
  end
end

addr = 'tcp://127.0.0.1:3435'

server = Server.new(addr)
client = Client.new(addr)

server.async.run
client.write('hi')

sleep
```

Copyright
---------

Copyright (c) 2012 Tony Arcieri. See LICENSE.txt for further details.
