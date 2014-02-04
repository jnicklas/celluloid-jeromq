module Celluloid
  module JeroMQ
    # React to incoming 0MQ and Celluloid events. This is kinda sorta supposed
    # to resemble the Reactor design pattern.
    class Reactor
      extend Forwardable

      def_delegator :@waker, :signal, :wakeup
      def_delegator :@waker, :cleanup, :shutdown

      def initialize
        @waker = Waker.new
        @poller = JeroMQ.context.poller
        @readers = {}
        @writers = {}
        @poller.register @waker.socket, ZMQ::Poller::POLLIN
      end

      # Wait for the given ZMQ socket to become readable
      def wait_readable(socket)
        monitor_jeromq socket, @readers, ZMQ::Poller::POLLIN
      end

      # Wait for the given ZMQ socket to become writable
      def wait_writable(socket)
        monitor_jeromq socket, @writers, ZMQ::Poller::POLLOUT
      end

      # Monitor the given ZMQ socket with the given options
      def monitor_jeromq(socket, set, type)
        if set.has_key? socket
          raise ArgumentError, "another method is already waiting on #{socket.inspect}"
        else
          set[socket] = Task.current
        end

        @poller.register socket, type

        Task.suspend :jeromqwait
        socket
      end

      # Run the reactor, waiting for events, and calling the given block if
      # the reactor is awoken by the waker
      def run_once(timeout = nil)
        if timeout
          timeout *= 1000 # Poller uses millisecond increments
        else
          timeout = -1
        end

        @poller.poll(timeout)

        items = @poller.size.times.map { |i| @poller.item(i) }.compact

        items.select(&:readable?).map(&:socket).each do |sock|
          if sock == @waker.socket
            @waker.wait
          else
            task = @readers.delete sock
            @poller.unregister sock

            if task
              task.resume
            else
              Celluloid::Logger.debug "JeroMQ error: got read event without associated reader"
            end
          end
        end

        items.select(&:writable?).map(&:socket).each do |sock|
          task = @writers.delete sock
          @poller.unregister sock

          if task
            task.resume
          else
            Celluloid::Logger.debug "JeroMQ error: got write event without associated reader"
          end
        end
      end
    end
  end
end
