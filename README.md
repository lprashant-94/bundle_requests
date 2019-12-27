# bundle_requests

[![Help Contribute to Open Source](https://www.codetriage.com/lprashant-94/bundle_requests/badges/users.svg)](https://www.codetriage.com/lprashant-94/bundle_requests)

This is the middleware which will combine multiple request from different clients, bundle as single request and process once using batch processing API. This works for rails threaded server e.g. PUMA.

![ScreenShot](https://raw.github.com/lprashant-94/bundle_requests/master/HighLevelDesign.jpg)

#### How it works.
This gem is designed for situations wherein large numberof  network calls throtten at database. This gem is specifically useful in case of microrequests which complete in very small time. Using this you can accumulate multiple requests and process them in bulk. While processing it in bulk we get a chance to do optimizations in code and pipeline them in network calls.

Internal design of gem is based on Producer-Consumer model. This gem is only for multithreaded rails server. This provides you rack middleware which will run on top of your existing rails middleware stack. While initialising middleware it will automatically spawn consumer thread.
Now after receiving request on thread, each thread will push request into common Queue and will sleep. In this way, as time goes on it will accumulate multiple requests in Queue.
Consumer will wake up after completing its sleep time and read all requests. Then it will create new request to bundle_api which is optimised and will send all the data in JSON same as below.
```
{"requests" => [request1, request2]}
```
Now its duty of bundle_api to handle all these requests's content and respond back with array of responses corresponding to each request. Here ensure that index of each response is associated with index in request array.
```
{"response" : [[200,{"Content-Type" => "application/json"},["Status Ok"]], [200,{"Content-Type" => "application/json"},["Status Ok"]]   ]}
```

Once consumer gets all these responses, it will distribute those responses back to each thread and will wake them up.
Once threads wake up they respond client with correct response, and start waiting for next request.
Consumer will first check if number of waiting requests are outnumbered max_waiting_thread otherwise it will sleep for wait_time and process new requests. In this way cycle goes on.

To get started, add BundleRequests::RackMiddleware into application.rb same as below example.


```
config.middleware.insert_before 0, BundleRequests::RackMiddleware, {
        "incoming_request" => "/api",
        "bundle_api" => "/bundle_api",
        "wait_time" => 10,
        "max_waiting_thread" => 16
      }
```
#### Configuration Parameters
1. incoming_request - url at which client sends request.
2. bundle_api - optimised bundle api to which all requests are forwarded.
3. wait_time - Sleep time to accumulate incoming requests in seconds. (Use floating point numbers for ms. 10ms - 100ms will be good range for production)
4. max_waiting_thread - If number of waiting threads hit max count then wait_time will be skipped. (This will depend on application, 5-100 will work great. Also configure number of server threads accordingly. )

*Important note is Benchmark your configurations for best results*

#### TASKLIST
- [x] Update readme correctly - Use code block and all
- [x] Use thread stop and wakeup and remove locks
- [ ] Test current gem on sample project
- [ ] Write specs for gem
- [x] Refactor code make it simple
- [ ] Divide code into multiple files
- [ ] Create Documentation and gather its usecases.
- [x] Switch to Producer-Consumer model, shift all master code to producer and consumer will just wait for producers signal
- [x] Use Thread local variable for results and remove instance variable. Minimize instance variables
- [ ] Use Thread pool for consumers
- [ ] Support for multiple api's
- [x] Have Maximum number of waiting threads, to bypass sleep call



#### Usecases
- Mongodb Batch insert while ensuring each request's its status
- Pipelined Redis calls
- Pull common data just once
- lot of lightwieght requests

#### Limitations
- Headers are not passed to request handler
- Supports only post requests (Currently.)
- All clients need to wait for some time (User can do middleware configuration in such a way that it wont affect user experience and run with maximal capacity. Keeping wait_time less than 10-20ms also works great.)
- Need to write new bundle api

### Other similar ideas:
- https://microservice-api-patterns.org/patterns/quality/dataTransferParsimony/RequestBundle.html
