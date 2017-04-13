# bundle_requests



This is the middleware which will combine multiple request from different client, bundle as single request and process once using batch processing api. This works for rails threaded server e.g. PUMA.


![ScreenShot](https://raw.github.com/lprashant-94/bundle_requests/master/HighLevelDesign.jpg)

For getting started add BundleRequests::RackMiddleware into application.rb same as below example.


```
config.middleware.insert_before 0, BundleRequests::RackMiddleware, {
        "incoming_request" => "/api",
        "bundle_api" => "/bundle_api",
        "wait_time" => 10,
        "thread_wait_after_closing_entrance" => 2,
        "max_waiting_thread" => 16
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
- [ ] Switch to Producer-Consumer model, Shift all master code to producer and consumer will just wait for producers signal
- [ ] Use Thread local variable for results and remove instance variable. Minimize instance variables
- [ ] Use Thread pool for consumers
- [ ] Support for multiple api's 
- [ ] Have Maximum number of waiting threads, to bypass sleep call
