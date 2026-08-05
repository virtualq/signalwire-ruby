# frozen_string_literal: true

require 'spec_helper'

module Signalwire
  RSpec.describe REST::Client do
    after { Signalwire::Sdk.reset }

    it 'makes the correct request' do
      stub_signalwire_env

      Signalwire::Sdk.configure do |config|
        config.hostname = 'myswspace.signalwire.com'
      end

      @client = Signalwire::REST::Client.new 'MYSWPROJECT',
                                             'MYSWTOKEN'

      stub = stub_request(:post, 'https://myswspace.signalwire.com/2010-04-01/Accounts/MYSWPROJECT/Messages.json')
             .with(body: { 'Body' => 'This is a message from the Signalwire-Ruby library!',
                           'From' => '+15556677999', 'To' => '+15558866555' })

      @message = @client.messages.create(
        from: '+15556677999',
        to: '+15558866555',
        body: 'This is a message from the Signalwire-Ruby library!'
      )

      expect(stub).to have_been_requested
    end

    # Host resolution reads these directly, so every example below pins them
    # rather than inheriting whatever the developer's shell happens to export.
    def stub_signalwire_env(host: nil, api_hostname: nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SIGNALWIRE_HOST').and_return(host)
      allow(ENV).to receive(:[]).with('SIGNALWIRE_API_HOSTNAME').and_return(api_hostname)
    end

    describe 'api_host:' do
      before { stub_signalwire_env }

      it 'overrides the api.twilio.com literal for twilio clients' do
        client = Signalwire::REST::Client.new 'AC123', 'TOKEN',
                                              service_provider: 'twilio',
                                              api_host: 'simulator.example.com'

        expect(client.api.hostname).to eq('simulator.example.com')
      end

      it 'overrides SIGNALWIRE_HOST when it is set in the environment' do
        stub_signalwire_env(host: 'env.signalwire.com')

        client = Signalwire::REST::Client.new 'PROJECT', 'TOKEN',
                                              api_host: 'simulator.example.com'

        expect(client.api.hostname).to eq('simulator.example.com')
      end

      it 'sends requests to the overridden host' do
        Signalwire::Sdk.configure { |config| config.hostname = 'myswspace.signalwire.com' }

        client = Signalwire::REST::Client.new 'MYSWPROJECT', 'MYSWTOKEN',
                                              api_host: 'simulator.example.com'

        stub = stub_request(:post, 'https://simulator.example.com/2010-04-01/Accounts/MYSWPROJECT/Messages.json')

        client.messages.create(from: '+15556677999', to: '+15558866555', body: 'hi')

        expect(stub).to have_been_requested
      end

      it 'keeps a separate host per client in the same process' do
        Signalwire::Sdk.configure { |config| config.hostname = 'myswspace.signalwire.com' }

        overridden = Signalwire::REST::Client.new 'PROJECT', 'TOKEN',
                                                  api_host: 'simulator.example.com'
        plain = Signalwire::REST::Client.new 'PROJECT', 'TOKEN'

        expect(overridden.api.hostname).to eq('simulator.example.com')
        expect(plain.api.hostname).to eq('myswspace.signalwire.com')
      end

      it 'ignores a blank override' do
        Signalwire::Sdk.configure { |config| config.hostname = 'myswspace.signalwire.com' }

        client = Signalwire::REST::Client.new 'PROJECT', 'TOKEN', api_host: '  '

        expect(client.api.hostname).to eq('myswspace.signalwire.com')
      end

      it 'stores the host with surrounding whitespace removed' do
        client = Signalwire::REST::Client.new 'PROJECT', 'TOKEN', api_host: " simulator.example.com\n"

        expect(client.api.hostname).to eq('simulator.example.com')
      end
    end

    describe 'without api_host:' do
      before { stub_signalwire_env }

      it 'uses api.twilio.com for twilio clients' do
        client = Signalwire::REST::Client.new 'AC123', 'TOKEN', service_provider: 'twilio'

        expect(client.api.hostname).to eq('api.twilio.com')
      end

      it 'uses SIGNALWIRE_HOST when set' do
        stub_signalwire_env(host: 'env.signalwire.com')

        client = Signalwire::REST::Client.new 'PROJECT', 'TOKEN'

        expect(client.api.hostname).to eq('env.signalwire.com')
      end

      it 'falls back to SIGNALWIRE_API_HOSTNAME' do
        stub_signalwire_env(api_hostname: 'legacy.signalwire.com')

        client = Signalwire::REST::Client.new 'PROJECT', 'TOKEN'

        expect(client.api.hostname).to eq('legacy.signalwire.com')
      end

      it 'falls back to the configured hostname' do
        client = Signalwire::REST::Client.new 'PROJECT', 'TOKEN',
                                              signalwire_space_url: 'configured.signalwire.com'

        expect(client.api.hostname).to eq('configured.signalwire.com')
      end

      it 'raises when no host is configured at all' do
        Signalwire::Sdk.configure { |config| config.hostname = nil }

        expect do
          Signalwire::REST::Client.new('PROJECT', 'TOKEN').api
        end.to raise_exception ArgumentError, /SignalWire Space URL is not configured/
      end
    end

    it 'leaves a plain Twilio client unaffected' do
      stub_signalwire_env
      Signalwire::Sdk.configure { |config| config.hostname = 'myswspace.signalwire.com' }

      expect(Twilio::REST::Client.new.api.hostname).to eq('myswspace.signalwire.com')
    end
  end
end
