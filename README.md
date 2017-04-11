# bundle_requests



This is the middleware which will combine multiple request from different client, bundle as single request and process once using batch processing api. This works for rails threaded server e.g. PUMA.


For getting started add BundleRequests::RackMiddleware into application.rb same as below example.


```
config.middleware.insert_before 0, BundleRequests::RackMiddleware {
        "incoming_request" => "/api",
        "bundle_api" => "/bundle_api",
        "wait_time" => 10,
        "thread_wait_at_lock" => 2,
        "thread_wait_after_closing_entrance" => 2
      }
```



#### TASKLIST 
- [x] Update readme correctly - Use code block and all
- [ ] Use thread stop and wakeup and remove locks
- [ ] Test current gem on sample project
- [ ] write specs for gem
- [ ] Refactor code make it simple
- [ ] Divide code into multiple files
- [ ] Create Documentation and gather its usecases.

