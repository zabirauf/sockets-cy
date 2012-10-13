Socket library for Cycript 
==========================
This uses the C socket library by dynamicaly linking to them and then creating a wrapper on it for easy socket programming in Cycript.

Usage
-----
Make sure you have include the file in the REPL or your .cy file.

```javascript
//Example of TCP Client
// Initialize the object

var onOpen    = function () { ... };
var onClose   = function() { ... };
var onMessage = function(data) { ... };

// You cal also use this.send(data) in the function to send data back to the server. 

var sock = BlockingSocket(host,port,onOpen,onClose,onMessage);
// Loop for data
// .run() is a blocking call

sock.run()
```

You can also create a TCP server as following

```javascript
//Example TCP Server
//Initialize the object

var onSocketCreated = function() {...};
var onConnectionOpen = function(){...};
var onConnectionClose = function(){...};
var onMessage = function(data,sockaddrRef){...};

// You cal also use this.send(data) in the function to send data back to the server. 

var HOST = "0.0.0.0"
var PORT = 9005

var sock = new TCPServer(HOST,PORT,onSocketCreated,onConnectionOpen,onConnectionClose,onMessage);
// Loop for data
// .serve() is a blocking call which waits for connection
// Only one connection is handled at a time. As its synchronous.
sock.serve();

```

TODO
----

Its just a basic library. So many things are missing. Currently it connects to TCP server and also can act as TCP Server. 
* Make it asynchronous


## License

Copyright (c) 2012 Zohaib Rauf

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
  copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
  OTHER DEALINGS IN THE SOFTWARE.
