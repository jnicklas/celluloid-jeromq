module Celluloid
  module JeroMQ
    class Socket
      # Create a new socket
      def initialize(type)
        @socket = Celluloid::JeroMQ.context.socket ZMQ.const_get(type.to_s.upcase)
        @linger = 0
      end
      attr_reader :linger

      # Connect to the given 0MQ address
      # Address should be in the form: tcp://1.2.3.4:5678/
      def connect(addr)
        @socket.connect(addr)
        true
      end

      def linger=(value)
        @linger = value || -1
        @socket.linger = linger
      end

      def identity=(value)
        @socket.identity = value.to_java_bytes
      end

      def identity
        @socket.identity
      end

      # Bind to the given 0MQ address
      # Address should be in the form: tcp://1.2.3.4:5678/
      def bind(addr)
        @socket.bind(addr)
      end

      # Close the socket
      def close
        @socket.close
      end

      # Hide ffi-rjeromq internals
      alias_method :inspect, :to_s
    end

    # Readable 0MQ sockets have a read method
    module ReadableSocket
      extend Forwardable

      # always set LINGER on readable sockets
      def bind(addr)
        self.linger = @linger
        super(addr)
      end

      def connect(addr)
        self.linger = @linger
        super(addr)
      end

      # Read a message from the socket
      def read
        JeroMQ.wait_readable(@socket) if JeroMQ.evented?

        @socket.recv_str
      end

      # Multiparts message ?
      def_delegator :@socket, :more_parts?
    end

    # Writable 0MQ sockets have a send method
    module WritableSocket
      # Send a message to the socket
      def write(*messages)
        @socket.send_strings(messages.flatten)
        messages
      end
      alias_method :<<, :write
      alias_method :send, :write # deprecated
    end

    # ReqSockets are the counterpart of RepSockets (REQ/REP)
    class ReqSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :req
      end
    end

    # RepSockets are the counterpart of ReqSockets (REQ/REP)
    class RepSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :rep
      end
    end

    # DealerSockets are like ReqSockets but more flexible
    class DealerSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :dealer
      end
    end

    # RouterSockets are like RepSockets but more flexible
    class RouterSocket < Socket
      include ReadableSocket
      include WritableSocket

      def initialize
        super :router
      end
    end

    # PushSockets are the counterpart of PullSockets (PUSH/PULL)
    class PushSocket < Socket
      include WritableSocket

      def initialize
        super :push
      end
    end

    # PullSockets are the counterpart of PushSockets (PUSH/PULL)
    class PullSocket < Socket
      include ReadableSocket

      def initialize
        super :pull
      end
    end

    # PubSockets are the counterpart of SubSockets (PUB/SUB)
    class PubSocket < Socket
      include WritableSocket

      def initialize
        super :pub
      end
    end

    # SubSockets are the counterpart of PubSockets (PUB/SUB)
    class SubSocket < Socket
      include ReadableSocket

      def initialize
        super :sub
      end

      def subscribe(topic)
        @socket.subscribe(topic.to_java_bytes)
      end

      def unsubscribe(topic)
        @socket.unsubscribe(topic.to_java_bytes)
      end
    end
  end
end
