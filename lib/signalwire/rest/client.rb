# frozen_string_literal: true

module Signalwire::REST
  class Client < Twilio::REST::Client
    # Per-instance REST API hostname. When set, this client's API domain talks to
    # this host instead of the process-wide configuration or environment.
    attr_reader :api_host

    def initialize(username = nil, password = nil, account_sid = nil, region = nil, http_client = Twilio::HTTP::Client.new, **args)
      host = args.delete(:signalwire_space_url)
      service_provider = args.delete(:service_provider)
      api_host = args.delete(:api_host)

      @api_host = api_host.strip if api_host.is_a?(String) && !api_host.strip.empty?

      Signalwire::Sdk.configure do |config|
        config.hostname = host if host
        config.service_provider = service_provider if service_provider
      end

      super(username, password, account_sid, region, http_client)
    end
  end
end