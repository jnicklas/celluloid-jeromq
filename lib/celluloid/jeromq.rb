require 'celluloid'
require 'celluloid/jeromq/jeromq.jar'
require 'celluloid/jeromq/mailbox'
require 'celluloid/jeromq/reactor'
require 'celluloid/jeromq/sockets'
require 'celluloid/jeromq/version'
require 'celluloid/jeromq/waker'
require 'set'

module Celluloid
  # Actors which run alongside 0MQ sockets
  module JeroMQ
    ZMQ = org.zeromq::ZMQ

    UninitializedError = Class.new StandardError

    @mutex = Mutex.new

    class << self
      attr_writer :context

      # Included hook to pull in Celluloid
      def included(klass)
        klass.send :include, ::Celluloid
        klass.mailbox_class Celluloid::JeroMQ::Mailbox
      end

      # Obtain a 0MQ context
      def init(worker_threads = 1)
        @mutex.synchronize do
          unless @context
            @context = ZMQ.context(worker_threads)
            @sockets = Set.new
          end
          @context
        end
      end

      def context
        raise UninitializedError, "you must initialize Celluloid::JeroMQ by calling Celluloid::JeroMQ.init" unless @context
        @context
      end

      def open_socket(type)
        @mutex.synchronize do
          raise UninitializedError, "cannot create socket" unless @sockets
          socket = Celluloid::JeroMQ.context.socket ZMQ.const_get(type.to_s.upcase)
          @sockets.add(socket)
          socket
        end
      end

      def close_socket(socket)
        @mutex.synchronize do
          socket.close
          @sockets.delete(socket) if @sockets
        end
      end

      def terminate
        @mutex.synchronize do
          @sockets.each(&:close) if @sockets
          @context.term if @context
          @sockets = nil
          @context = nil
        end
      end
    end

    # Is this a Celluloid::JeroMQ evented actor?
    def self.evented?
      actor = Thread.current[:celluloid_actor]
      actor.mailbox.is_a?(Celluloid::JeroMQ::Mailbox)
    end

    def wait_readable(socket)
      if JeroMQ.evented?
        mailbox = Thread.current[:celluloid_mailbox]
        mailbox.reactor.wait_readable(socket)
      else
        raise ArgumentError, "unable to wait for ZMQ sockets outside the event loop"
      end
      nil
    end
    module_function :wait_readable

    def wait_writable(socket)
      if JeroMQ.evented?
        mailbox = Thread.current[:celluloid_mailbox]
        mailbox.reactor.wait_writable(socket)
      else
        raise ArgumentError, "unable to wait for ZMQ sockets outside the event loop"
      end
      nil
    end
    module_function :wait_writable

  end
end
