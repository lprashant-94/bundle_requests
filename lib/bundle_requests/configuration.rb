
module BundleRequests

  CONFIGURATION_OPTIONS = {
    incoming_request: "/api/v3/things/event.json",
    bundle_api: "api/v3/things/batchevent",
    wait_time: 10,
    thread_wait_at_lock: 2,
    thread_wait_after_closing_entrance: 2
  }

  # Batch API Configuration
  class Configuration < Struct.new(*CONFIGURATION_OPTIONS.keys)
    # Public: initialize a new configuration option and apply the defaults.
    def initialize
      super
      CONFIGURATION_OPTIONS.each {|k, v| self[k] = v}
    end
  end
end


