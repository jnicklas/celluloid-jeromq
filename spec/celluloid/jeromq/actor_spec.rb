require 'spec_helper'
require 'celluloid/rspec'

describe Celluloid::JeroMQ do
  it_behaves_like "a Celluloid Actor", Celluloid::JeroMQ
end
