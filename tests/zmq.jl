
load ("jl/zmq.jl")


@assert zmq_version() == (2,1,11)

ctx=zmq_init(1)

@assert typeof(ctx) == ZMQ_Context

try 
	zmq_init(-1)
	@assert false
catch ex
	@assert matches(r"ZMQ::init", string(ex))
end 

zmq_term(ctx)

#try to create socket with expired context
try 
	zmq_socket(ctx, ZMQ_PUB)
	@assert false
catch ex
	@assert matches(r"ZMQ::socket", string(ex))
end


ctx2=zmq_init(1)
s=zmq_socket(ctx2, ZMQ_PUB)
@assert typeof(s) == ZMQ_Socket
zmq_close(s)

#trying to close already closed socket
try 
	zmq_close(s)
catch ex
	@assert matches(r"ZMQ::close", string(ex))
end


s1=zmq_socket(ctx2, ZMQ_REP)
zmq_setsockopt(s1, ZMQ_HWM, 1000)
zmq_setsockopt(s1, ZMQ_LINGER, 1)
zmq_setsockopt(s1, ZMQ_IDENTITY, "abcd")

@assert zmq_getsockopt(s1, ZMQ_IDENTITY)::String == "abcd"
@assert zmq_getsockopt(s1, ZMQ_HWM)::Integer == 1000
@assert zmq_getsockopt(s1, ZMQ_LINGER)::Integer == 1
@assert zmq_getsockopt(s1, ZMQ_RCVMORE) == false 

s2=zmq_socket(ctx2, ZMQ_REQ)
@assert zmq_getsockopt(s1, ZMQ_TYPE) == ZMQ_REP 
@assert zmq_getsockopt(s2, ZMQ_TYPE) == ZMQ_REQ 

zmq_bind(s1, "tcp://*:5555")
zmq_connect(s2, "tcp://localhost:5555")

zmq_send(s2, "test request")
@assert (zmq_recv(s1) == "test request")
zmq_send(s1, "test response")
@assert (zmq_recv(s2) == "test response")

zmq_close(s1)
zmq_close(s2)
zmq_term(ctx2)






