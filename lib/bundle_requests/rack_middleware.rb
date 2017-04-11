module BundleRequests
  class RackMiddleware
    def initialize(app, config={})
      @app = app
      @requests_counter = 0 
      @entrance_lock = Mutex.new
      @exit_lock =Mutex.new
      #exit_lock should be locked initially, test if I really need exit_lock or thread join will work for me
      @sync_mutex =Mutex.new
      @thread_env_queue = Queue.new
      @result = {}

      @configuration = generate_config_hash(config)

    end

    def call env
      r = []
      s = Time.now
      puts "*************#{Thread.current.name} #{Time.now.to_f*1000}   **************"
    
      if env['REQUEST_PATH'] == @configuration['incoming_request']
        # Event injection api
        
        #wait if any batch is currently getting processed
        #trying to make busy wait normal


        # Replace this locking mechanism with stop and wakeup ...
        while @entrance_lock.locked?
          sleep(@configuration['thread_wait_at_lock'])
        end
        
        @sync_mutex.synchronize do 
          if !@exit_lock.locked?
            @exit_lock.lock
            puts "Locking 2nd lock"
          end
        end

        @thread_env_queue << [Thread.current, env]

        if @exit_lock.owned?
          # Frequency of batch in seconds
          sleep(@configuration['wait_time'])
          @entrance_lock.lock
          puts "Locking 1st lock"
          #adding sleep just to make sure even if thread has not completed queue
          #This point is very important Need to add correct sync here
          # I used acquire 1st lock and some requests have already entered inside
          sleep(@configuration['thread_wait_after_closing_entrance'])
          @requests_counter = @thread_env_queue.length

          current_threads = []
          env_array = []
          @requests_counter.times do 
            temp = @thread_env_queue.pop
            current_threads << temp[0]
            env_array << temp[1]
          end

          #reset all requests result before continue
          @result.clear
          #Write code for master thread to query data and distribute among waiting threads
          puts "I am processing #{@requests_counter}"
          puts "Thread Object ID are "
          
          #call batch event api from here
          #request_path, request_uri, body
          my_env = env
          rack_input = []
          env_array.each do |e|
            # byebug
            req = Rack::Request.new(e)
            puts req.inspect
            rack_input << JSON.parse(req.body.read)
            # req.body.close if   req.body.respond_to? :close
            # byebug
          end
          puts rack_input
          my_env['PATH_INFO'] = @configuration['bundle_api']
          my_env['QUERY_STRING'] = ''
          my_env['REQUEST_METHOD'] = 'POST'
          my_env['CONTENT_LENGTH'] = {'requests' => rack_input}.to_json.length
          # Body Is going null Test this tommorow :)
          my_env['rack.input'] = StringIO.new({'requests' => rack_input}.to_json)
          # puts 'Calling API'
          # byebug
          my_request = Rack::Request.new(my_env)
          temp_result = @app.call(my_env)
          # my_request.body.close if   my_request.body.respond_to? :close
          puts 'Completed API call'
          # byebug
          #UPTO here 

          #Thread names are repitative as fork is used to create them intenrally
          current_threads.each do |t|
            puts t.object_id 
            @result[t.object_id] = [200,{"Content-Type" => "application/json"},["Status Ok"]]
          end
          # reset all variable and go out
          env_array = []
          current_threads =[]
          # @requests_counter = 0

          @exit_lock.unlock
          puts "Unlock 2nd lock going out"
        end

        puts "#{Thread.current.name}Waiting for 2nd lock to open"
        # wait until master complets his work you are slaves :D 
        while @exit_lock.locked?
          sleep(0.005)
        end

        #distribute results before opening upper doar, 
        @sync_mutex.synchronize do 
          #everyone picks up there responses for array and goes home happily
          puts "Decrementing request counter #{@requests_counter} #{Thread.current.name}"
          r = @result[Thread.current.object_id]
          # puts "r is #{r}"
          @requests_counter -=1
        end

        if @entrance_lock.owned?
          #wait until everyone receives there responses
          while @requests_counter !=0
            sleep(0.001)
          end
          puts "opening entrance_lock"
          @entrance_lock.unlock
        end

      else
        puts "[Not event api] Thread Entered"
        r = @app.call env
        puts "[Not event api] Thread exited"
      end

      f = Time.now
      # puts "value of r = #{r} Returning below end time #{@requests_counter} #{Time.now.to_f*1000}   --------------"
      puts "TIME required for request to process is -#{Time.now - s} "
      r
      # do something...
    end

    def generate_config_hash(options)
      config = {
        "incoming_request" => "/api",
        "bundle_api" => "/bundle_api",
        "wait_time" => 10,
        "thread_wait_at_lock" => 2,
        "thread_wait_after_closing_entrance" => 2
      }

      options.each do |key,value|
        if !value.nil?
          config[key] = value
        end
      end
      config
    end



  end
end
