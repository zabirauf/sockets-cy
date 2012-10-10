#!/usr/bin/cycript
/**
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
**/
dynamicLinkSymbol = function (s,handle=RTLD_DEFAULT) { return dlsym(handle,s); }
_SIZE_OF_SOCKADDR = 16;

_socket = dynamicLinkSymbol("socket");
_htons = dynamicLinkSymbol("htons");
_socketpair = dynamicLinkSymbol("socketpair");
_close = dynamicLinkSymbol("close");
_read = dynamicLinkSymbol("read");
_write = dynamicLinkSymbol("write");
_inet_addr = dynamicLinkSymbol("inet_addr");
_memset = dynamicLinkSymbol("memset");
_sendto = dynamicLinkSymbol("sendto");
_perror = dynamicLinkSymbol("perror");
_connect = dynamicLinkSymbol("connect");
_accept = dynamicLinkSymbol("accept");
_bind = dynamicLinkSymbol("bind");
_listen = dynamicLinkSymbol("listen");

socketpair =  new Functor(_socketpair,"iiii[2i]");
//int socket(int domain, int type, int protocol);
socket = new Functor(_socket,"iiii");
//ssize_t read(int fd, void *buf, size_t count);
read = new Functor(_read,"Ii^vI");
//ssize_t write(int fd, const void *buf, size_t count);
write = new Functor(_write,"Ii^rvI");
//int close(int fd);
close = new Functor(_close,"ii");
//in_addr_t	 inet_addr(const char *); here in_addr_t is unsigned int
inet_addr = new Functor(_inet_addr,"I^C");

htons = new Functor(_htons,"SS");

//void * memset ( void * ptr, int value, size_t num );
memset = new Functor(_memset,"^v^viI");
//memset = new function(ptr,value,num){ return __memset(ptr,int(value),new Type("I")(num)) ;}

//ssize_t sendto(int sockfd, const void *buf, size_t len, int flags,const struct sockaddr *dest_addr, socklen_t addrlen);
sendto = new Functor(_sendto,"li^rvIi^r{sockaddr=CC[14c]}I");
//void perror(const char *s);
perror = new Functor(_perror,"v^rc");
//int connect(int sockfd, const struct sockaddr *addr,socklen_t addrlen);
connect = new Functor(_connect,"ii^r{sockaddr=CC[14c]}I");
//int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
accept = new Functor(_accept,"ii^{sockaddr=CC[14c]}^I");
//int bind(int sockfd, const struct sockaddr *addr,socklen_t addrlen);
bind = new Functor(_bind,"ii^r{sockaddr=CC[14c]}I");
//int listen(int sockfd, int backlog);
listen = new Functor(_listen,"iii");


AF_UNIX	= 1;
AF_INET = 2;
SOCK_STREAM	= 1;
SOCK_DGRAM	= 2;



function create_array(type,size,sizeOfType){
	ttype = "["+size+type+"]";
	return new Pointer(malloc(sizeOfType),ttype);
}

function object_at_index(arr,index,typeOfObject,sizeOfType){
	return *new Pointer(arr+(sizeOfType)*index,typeOfObject)
}

function write_to_mem(addr,string){

	for(var i=0;i<[string length];i++){
		p = new Pointer(addr+i,"c");
		*p = char([string characterAtIndex:i]);
	}
}

function create_c_string(string){
	str = new Pointer(malloc([string length]+1),"C");
	write_to_mem(str,string);
	*(new Pointer(str+[string length],"c")) = 0;
	return str;
}

function string_from_buffer(stringRef){
	var str="";
	var i=0;
	while(c = *(new Pointer(stringRef+i,"C")) ) {
		str += String.fromCharCode(c);
		i++;
	}

	return str;
}

// typedef unsigned char __uint8_t
// typedef sa_family_t __uint8_t
// typedef	__uint16_t		in_port_t;
// typedef unsigned short		__uint16_t;
/*
struct sockaddr_in {
	__uint8_t	sin_len;
	sa_family_t	sin_family;
	in_port_t	sin_port;
	struct	in_addr sin_addr;
	char		sin_zero[8];
};
//typedef	__uint32_t		in_addr_t;
struct in_addr {
	in_addr_t s_addr;
};
*/

function create_sockaddr_in(family,ip,port){
	_family = new Type("C")(family);
	ip_c_str = create_c_string(ip)
	_s_addr = inet_addr(ip_c_str);
	_sin_port = htons(new Type("S")(port));
	_sin_zero = new Pointer(malloc(8),"C");
	memset(_sin_zero,0,8);
	free(ip_c_str);
	return {
		sin_len:new Type('C')(0),
		sin_family:_family,
		sin_port:_sin_port,
		sin_addr:{s_addr:_s_addr},
		sin_zero:_sin_zero
	};
}

function free_sockaddr(sockaddr){
	free(new Pointer(sockaddr.sin_zero,"l"));
}


function convert_sockaddr_to_pointer(sockaddr){
	sockaddrRef = new Pointer(malloc(16),"C");
	*sockaddrRef = sockaddr.sin_len;
	*(new Pointer(sockaddrRef+1,"C")) = sockaddr.sin_family;
	*(new Pointer(sockaddrRef+2,"S")) = sockaddr.sin_port;
	*(new Pointer(sockaddrRef+4,"I")) = sockaddr.sin_addr.s_addr;
	memset(new Pointer(sockaddrRef+8,"C"),0,8);

	return sockaddrRef;
}


function BlockingSocket(host,port,onOpen,onClose,onMessage){
	
	this.host = host;
	this.port = port; 
	this.onOpen = onOpen;
	this.onClose = onClose;
	this.onMessage = onMessage;
	
	this._BUFFER_SIZE = 4096;
	this._sockfd = -1;
	this._sockaddr = null;
	this._sockaddrRef= null;
	this._buffer = null;

	this.send = function(data){
		w = write(this._sockfd,create_c_string(data),data.length);
		if(w<0){ c_str = create_c_string("Error writing"); perror(c_str); free(c_str);}
		return w;
	}

	this.run = function(){
		this._run();
	}


	this._connect = function(){
		this._sockfd = socket(AF_INET,SOCK_STREAM,0);
		this._sockaddr = create_sockaddr_in(AF_INET,this.host,this.port);
		this._sockaddrRef = convert_sockaddr_to_pointer(this._sockaddr);
		c = connect(this._sockfd,this._sockaddrRef,_SIZE_OF_SOCKADDR);
		if(c<0){
			c_str = create_c_string("Error Connecting");
			perror(c_str);
			free(c_str);
		}
		this.onOpen();
		return c;
	};
	this._close = function(){
		close(this._sockfd);
		free_sockaddr(this._sockaddr);
		free(this._sockaddrRef);
		if(this._buffer!=null) free(this._buffer);
		this.onClose();
	};
	this._message = function(data){
		this.onMessage(data);
	};
	this._run = function(){
		if(this._connect()<0) return null;
		this._buffer = new Pointer(malloc(this._BUFFER_SIZE),"C");	
		readValue = 0;
		while(true){
			memset(this._buffer,0,this._BUFFER_SIZE);
			readValue = read(this._sockfd,this._buffer,this._BUFFER_SIZE);
			if(readValue<=0) { /*c_str = create_c_string("Error Reading"); perror(c_str); free(c_str);*/ break;}
			this._message(string_from_buffer(this._buffer));
		}

		this._close();

	}

}