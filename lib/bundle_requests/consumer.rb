module BundleRequests
  class Consumer
    def initialize
      Thread.new{consumer_code}
    end

    def consumer_code
      
    end

  end
end