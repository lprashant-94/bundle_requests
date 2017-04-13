module BundleRequests
  class Consumer
    def initialize(app , config)
      @app = app
      $waiting_threads = Queue.new
      generate_config_hash(config)
      Thread.new{consumer_code}
    end

    def get_waiting_threads
      $waiting_threads
    end

    def get_configuration
      $configuration
    end
# List All Instance Variables here for reference 
# - @app
# - $configuration
# - @consumer
# - $waiting_threads

    def consumer_code
      while true
        c = $waiting_threads.length
        if c < $configuration["max_waiting_thread"]
          puts "#{c} threads are waiting so sleeping"
          sleep($configuration["wait_time"])
          next if $waiting_threads.length == 0
        end
        puts "Started request processing----------------------------------"
        threads = pop_some_waiting_threads
        rack_input = gather_all_requests(threads)
        result = call_bundle_api(rack_input,threads[0]['request'])      # may through exception if 0 threads are present remove it afterwards
        distribute_result_and_wakeup_those_threads(threads, result)
        puts "Completed proccessing requests------------------------------"
      end      
    end

    def pop_some_waiting_threads
      threads = []
      $waiting_threads.length.times do
        t = $waiting_threads.pop
        threads << t
      end
      Rails.logger.info("Currently proccessing #{threads.length} threads")
      threads
    end

    def gather_all_requests(threads)
      rack_input = []
      threads.each do |t|
        e = t['request']
        req = Rack::Request.new(e)
        Rails.logger.info req.inspect
        rack_input << JSON.parse(req.body.read)
      end
      Rails.logger.info rack_input
      rack_input
    end

    def call_bundle_api(rack_input,default_env={})
      env = default_env             # if this doesnt work assign myenv to some env of any threads
      env['PATH_INFO'] = $configuration['bundle_api']
      env['QUERY_STRING'] = ''
      env['REQUEST_METHOD'] = 'POST'
      env['CONTENT_LENGTH'] = {'requests' => rack_input}.to_json.length
      env['rack.input'] = StringIO.new({'requests' => rack_input}.to_json)
      request = Rack::Request.new(env)
      Rails.logger.info("new Environment is #{env}")
      Rails.logger.info("New request content are #{request}")
      result = @app.call(env)
      Rails.logger.info("Result are #{result}")
      result
    end

    def distribute_result_and_wakeup_those_threads(threads, result)
      for index in 0...threads.length
        t = threads[index]
        # hardcoded response for development. Replace it with result[index]
        t["response"] = [200,{"Content-Type" => "application/json"},["Status Ok"]]
        t.wakeup
      end
    end

    def generate_config_hash(options)
      if $configuration.nil?
        config = {
          "incoming_request" => "/api",
          "bundle_api" => "/bundle_api",
          "wait_time" => 10,
          "thread_wait_after_closing_entrance" => 2,
          "max_waiting_thread" => 16
        }

        options.each do |key,value|
          if !value.nil?
            config[key] = value
          end
        end
        $configuration =  config
      end
    end

  end
end