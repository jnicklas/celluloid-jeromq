require 'spec_helper'

# find some available ports for JeroMQ
JEROMQ_PORTS = 10.times.map do
  begin
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end
end

describe Celluloid::JeroMQ do
  before do
    @context = ::ZMQ::Context.new(1)
    @sockets = []
  end

  after do
    @sockets.each(&:close)
    @context.terminate
  end

  let(:ports) { JEROMQ_PORTS }

  def connect(socket, index=0)
    socket.connect("tcp://127.0.0.1:#{ports[index]}")
    @sockets << socket
    socket
  end

  def bind(socket, index=0)
    socket.bind("tcp://127.0.0.1:#{ports[index]}")
    @sockets << socket
    socket
  end

  describe ".init" do
    xit "inits a JeroMQ context", :no_init do
      Celluloid::JeroMQ.init
      server = bind(Celluloid::JeroMQ.context.socket(::ZMQ::REQ))
      client = connect(Celluloid::JeroMQ.context.socket(::ZMQ::REP))

      server.send_string("hello world")
      message = ""
      client.recv_string(message)
      message.should eq("hello world")
    end

    it "can set JeroMQ context manually", :no_init do
      context = Celluloid::JeroMQ::ZMQ.context(1)
      Celluloid::JeroMQ.context = context
      Celluloid::JeroMQ.context.should eq(context)
    end

    it "raises an error when trying to access context and it isn't initialized", :no_init do
      expect { Celluloid::JeroMQ.context }.to raise_error(Celluloid::JeroMQ::UninitializedError)
    end

    it "raises an error when trying to access context after it is terminated" do
      Celluloid::JeroMQ.terminate
      expect { Celluloid::JeroMQ.context }.to raise_error(Celluloid::JeroMQ::UninitializedError)
      Celluloid::JeroMQ.init
      Celluloid::JeroMQ.context.should_not be_nil
    end
  end

  describe Celluloid::JeroMQ::RepSocket do
    let(:actor) do
      Class.new do
        include Celluloid::JeroMQ

        finalizer :close_socket

        def initialize(port)
          @socket = Celluloid::JeroMQ::RepSocket.new
          @socket.connect("tcp://127.0.0.1:#{port}")
        end

        def say_hi
          "Hi!"
        end

        def fetch
          @socket.read
        end

        def close_socket
          @socket.close
        end
      end
    end

    it "receives messages" do
      server = bind(@context.socket(::ZMQ::REQ))
      client = actor.new(ports[0])

      server.send_string("hello world")
      result = client.fetch
      result.should eq("hello world")
    end

    it "suspends actor while waiting for message" do
      server = bind(@context.socket(::ZMQ::REQ))
      client = actor.new(ports[0])

      result = client.future.fetch
      client.say_hi.should eq("Hi!")
      server.send_string("hello world")
      result.value.should eq("hello world")
    end
  end
end
