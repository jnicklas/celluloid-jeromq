require 'spec_helper'
require 'celluloid/rspec'

describe Celluloid::JeroMQ::Mailbox do
  it_behaves_like "a Celluloid Mailbox"
end
