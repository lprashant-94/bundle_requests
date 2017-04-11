module BundleRequests
  class Producer
    def initialize
      Thread.new{producer_code}
    end

    def producer_code
      
    end

  end
end