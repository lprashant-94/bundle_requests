require 'bundle_requests/consumer'
module BundleRequests
  class RackMiddleware
    def initialize(app, config={})
      @app = app
      @sync_mutex =Mutex.new
      start_consumer(config)
    end

    def start_consumer(config)
      @sync_mutex.synchronize do
        if @consumer.nil?
          @consumer =  BundleRequests::Consumer.new(config) # cretes new infinite thread
        end
      end
    end

    def call env
      Rails.logger.info("request #{env['REQUEST_PATH']} #{Thread.current.name}")
      s = Time.now
      if env['REQUEST_PATH'] == @configuration['incoming_request']
        Thread.current['request'] = env
        @waiting_threads << Thread.current
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
