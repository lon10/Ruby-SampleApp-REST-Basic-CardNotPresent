require 'time'
require 'open-uri'

module Evo
  class ServiceManagement
    def self.get_service_info(evo_cws_client)
      evo_cws_client.last_call = "#{self.name}::#{__method__.to_s}"
      evo_cws_client.send("#{RbConfig::BasePath}/svcinfo/serviceinformation", nil, Net::HTTP::Get, RbConfig::BaseURL);
    end
  end
end