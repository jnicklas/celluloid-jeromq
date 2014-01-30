module Celluloid
  module JeroMQ
    # Replacement mailbox for Celluloid::JeroMQ actors
    class Mailbox < Celluloid::EventedMailbox
      def initialize
        super(Reactor)
      end
    end
  end
end
