module Celluloid
  module JeroMQ
    # You can't wake the dead
    DeadWakerError = Class.new IOError

    # Wakes up sleepy threads so that they can check their mailbox
    # Works like a ConditionVariable, except it's implemented as a JeroMQ socket
    # so that it can be multiplexed alongside other JeroMQ sockets
    class Waker
      PAYLOAD = "\0" # the payload doesn't matter, it's just a signal

      def initialize
        @sender   = JeroMQ.context.socket(ZMQ::PAIR)
        @receiver = JeroMQ.context.socket(ZMQ::PAIR)

        @addr = "inproc://waker-#{object_id}"
        @sender.bind @addr
        @receiver.connect @addr

        @sender_lock = Mutex.new
      end

      # Wakes up the thread that is waiting for this Waker
      def signal
        @sender_lock.synchronize do
          @sender.send PAYLOAD
        end
      end

      # 0MQ socket to wait for messages on
      def socket
        @receiver
      end

      # Wait for another thread to signal this Waker
      def wait
        message = @receiver.recv_str
        raise DeadWakerError, "error receiving ZMQ string" unless message == PAYLOAD
      end

      # Clean up the IO objects associated with this waker
      def cleanup
        @sender_lock.synchronize { @sender.close rescue nil }
        @receiver.close rescue nil
        nil
      end
      alias_method :shutdown, :cleanup
    end
  end
end
