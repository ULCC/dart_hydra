# frozen_string_literal: true

# spec/spec_helper.rb
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.internal_test_app'
end

# coveralls
require 'coveralls'
Coveralls.wear!

# $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

# as of webmock v2 this has to go here, after load path and before other requires
require 'webmock/rspec'
require 'factory_bot_rails'
require 'engine_cart'

EngineCart.load_application!

require 'byebug' unless ENV['TRAVIS']

WebMock.disable_net_connect!(allow_localhost: true)

FactoryBot.definition_file_paths = [File.expand_path('../factories', __FILE__)]
FactoryBot.find_definitions

require 'active_fedora/cleaner'
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.expect_with :rspec do |c|
    c.syntax = %i[should expect]
  end
  config.before(:suite) do
    # nothing to do here
  end
  config.before do
    # nothing to do here
  end
  config.after(:suite) do
    ActiveFedora::Cleaner.clean!
  end

  # Fixtures
  # config.fixture_path = File.expand_path("../fixtures", __FILE__)
end
