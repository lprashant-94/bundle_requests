require 'bundle_requests/consumer'
module BundleRequests
  class RackMiddleware
    def initialize(app, config={})
      @app = app
      start_consumer(app, config)
    end
#   @consumer
#   @app
#   $waiting_threads
#   $configuration

    def start_consumer(app, config)
      Mutex.new.synchronize do
        if @consumer.nil?
          @consumer =  BundleRequests::Consumer.new(app, config) # cretes new infinite thread
        end
      end
    end

    def call env
      Rails.logger.info("request #{env['REQUEST_PATH']} #{Thread.current.name}")
      s = Time.now
      if env['REQUEST_PATH'] == $configuration['incoming_request']
        Thread.current['request'] = env
        $waiting_threads << Thread.current
        puts "I am waiting #{Thread.current.object_id}"
        Thread.stop
        response = Thread.current['response']
      else
        puts "[Not bundle api]"
        response = @app.call env
      end
      puts "TIME required for request to process is -#{Time.now - s} "
      response
    end

  end
end
