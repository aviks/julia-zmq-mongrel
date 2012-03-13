_jl_libzmq = dlopen("libzmq")

_jl_zmq_version = dlsym(_jl_libzmq, :zmq_version)
_jl_zmq_init = dlsym(_jl_libzmq, :zmq_init)
_jl_zmq_term = dlsym(_jl_libzmq, :zmq_term)
_jl_zmq_errno = dlsym(_jl_libzmq, :zmq_errno)
_jl_zmq_strerror = dlsym(_jl_libzmq, :zmq_strerror)

_jl_zmq_socket = dlsym(_jl_libzmq, :zmq_socket)
_jl_zmq_close = dlsym(_jl_libzmq, :zmq_close)
_jl_zmq_getsockopt = dlsym(_jl_libzmq, :zmq_getsockopt)
_jl_zmq_setsockopt = dlsym(_jl_libzmq, :zmq_setsockopt)

_jl_zmq_bind = dlsym(_jl_libzmq, :zmq_bind)
_jl_zmq_connect = dlsym(_jl_libzmq, :zmq_connect)

_jl_zmq_msg_init_size = dlsym(_jl_libzmq, :zmq_msg_init_size)
_jl_zmq_msg_init = dlsym(_jl_libzmq, :zmq_msg_init)
_jl_zmq_msg_data = dlsym(_jl_libzmq, :zmq_msg_data)
_jl_zmq_msg_size = dlsym(_jl_libzmq, :zmq_msg_size)
_jl_zmq_msg_close = dlsym(_jl_libzmq, :zmq_msg_close)
_jl_zmq_send = dlsym(_jl_libzmq, :zmq_send)
_jl_zmq_recv = dlsym(_jl_libzmq, :zmq_recv)


type ZMQ_Context
	data::Ptr{Void}
end
type ZMQ_Socket
	data::Ptr{Void}
end

function jl_zmq_error_str()
	errno = ccall(_jl_zmq_errno, Int32, ())
	c_strerror = ccall (_jl_zmq_strerror, Ptr{Uint8}, (Int32,), errno)
	if c_strerror != C_NULL
		strerror = cstring(c_strerror)
		return strerror
	else 
		return "Unknown error"
	end
end

function zmq_version()
	major = Array(Int32,1)
	minor = Array(Int32,1)
	patch = Array(Int32,1)

	ccall(_jl_zmq_version, Ptr{Void}, (Ptr{Int32}, Ptr{Int32}, Ptr{Int32}), major, minor, patch)
	return (major[1], minor[1], patch[1])
end

function zmq_init(n::Integer)
	rc = ccall(_jl_zmq_init, Ptr{Void},  (Uint32,), uint32(n))
	if rc == C_NULL
		error ("ZMQ::init::$(jl_zmq_error_str())")
	end
	return ZMQ_Context(rc)
end 

function zmq_term(ctx::ZMQ_Context)
	rc = ccall(_jl_zmq_term, Uint32,  (Ptr{Void},), ctx.data)
	if rc != 0
		error ("ZMQ::term::$(jl_zmq_error_str())")
	end

end 

function zmq_socket(ctx::ZMQ_Context, typ::Integer)
	rc = ccall(_jl_zmq_socket, Ptr{Void},  (Ptr{Void}, Uint32), ctx.data, uint32(typ))
	if rc == C_NULL
		error ("ZMQ::socket::$(jl_zmq_error_str())")
	end
	return ZMQ_Socket(rc)	
end

function zmq_close(socket::ZMQ_Socket)
	rc = ccall(_jl_zmq_close, Uint32,  (Ptr{Void},), socket.data)
	if rc != 0
		error ("ZMQ::close::$(jl_zmq_error_str())")
	end

end

function zmq_setsockopt(socket::ZMQ_Socket, option_name::Integer, option_value::Any)
	if (option_name == ZMQ_HWM || option_name == ZMQ_SWAP || option_name == ZMQ_AFFINITY || option_name == ZMQ_RATE || option_name == ZMQ_RECOVERY_IVL || option_name == ZMQ_MCAST_LOOP || option_name == ZMQ_SNDBUF || option_name == ZMQ_RCVBUF )
		option_ptr = Array(Uint64,1)
		option_ptr[1] = uint64(option_value)
		sz = uint(sizeof(Uint64))
		rc=ccall(_jl_zmq_setsockopt, Int32, (Ptr{Void}, Int32, Ptr{Void}, Uint), socket.data, int32(option_name), option_ptr, sz)

	elseif (option_name == ZMQ_LINGER || option_name == ZMQ_RECONNECT_IVL || option_name == ZMQ_BACKLOG || option_name == ZMQ_RECONNECT_IVL_MAX || option_name == ZMQ_RECOVERY_IVL_MSEC)
		option_ptr = Array(Int32,1)
		option_ptr[1] = int32(option_value)
		sz = uint(sizeof(Int32))
		rc=ccall(_jl_zmq_setsockopt, Int32, (Ptr{Void}, Int32, Ptr{Void}, Uint), socket.data, int32(option_name), option_ptr, sz)

	elseif (option_name == ZMQ_IDENTITY || option_name == ZMQ_SUBSCRIBE || ZMQ_UNSUBSCRIBE) 
		@assert length(option_value) < 255
		option_ptr = cstring(option_value)
		sz = uint(length(option_value))
		rc=ccall(_jl_zmq_setsockopt, Int32, (Ptr{Void}, Int32, Ptr{Uint8}, Uint), socket.data, int32(option_name), option_ptr, sz)
	else
		error("ZMQ::setsockopt::Unknown option type")
	end

	if (rc != 0) error ("ZMQ::setsockopt::$(jl_zmq_error_str())") ; end

end 

function zmq_getsockopt(socket::ZMQ_Socket, option_name::Integer)
	if (option_name == ZMQ_RCVMORE || option_name == ZMQ_HWM || option_name == ZMQ_SWAP || option_name == ZMQ_AFFINITY || option_name == ZMQ_RATE || option_name == ZMQ_RECOVERY_IVL || option_name == ZMQ_MCAST_LOOP || option_name == ZMQ_SNDBUF || option_name == ZMQ_RCVBUF )
		option_value_ptr = Array(Uint64,1)
		sz = Array(Uint, 1)
		sz[1] = uint(sizeof(Uint64))
		rc=ccall(_jl_zmq_getsockopt, Int32, (Ptr{Void}, Int32, Ptr{Void}, Ptr{Uint}), socket.data, int32(option_name), option_value_ptr, sz)
		if (rc != 0)  error ("ZMQ::getsockopt::$(jl_zmq_error_str())") ; end
		if (option_name == ZMQ_RCVMORE) 
			return bool(option_value_ptr[1])
		else
			return option_value_ptr[1]
		end

	elseif (option_name == ZMQ_TYPE || option_name == ZMQ_LINGER || option_name == ZMQ_RECONNECT_IVL || option_name == ZMQ_BACKLOG || option_name == ZMQ_RECONNECT_IVL_MAX || option_name == ZMQ_RECOVERY_IVL_MSEC)
		option_value_ptr = Array(Int32,1)
		sz = Array(Uint, 1)
		sz[1] = uint(sizeof(Int32))
		rc=ccall(_jl_zmq_getsockopt, Int32, (Ptr{Void}, Int32, Ptr{Void}, Ptr{Uint}), socket.data, int32(option_name), option_value_ptr, sz)
		if (rc != 0)  error ("ZMQ::getsockopt::$(jl_zmq_error_str())") ; end
		return option_value_ptr[1]

	elseif (option_name == ZMQ_EVENTS)
		option_value_ptr = Array(Uint32,1)
		sz = Array(Uint, 1)
		sz[1] = uint(sizeof(Uint32))
		rc=ccall(_jl_zmq_getsockopt, Int32, (Ptr{Void}, Int32, Ptr{Void}, Ptr{Uint}), socket.data, int32(option_name), option_value_ptr, sz)
		if (rc != 0)  error ("ZMQ::getsockopt::$(jl_zmq_error_str())") ; end
		return option_value_ptr[1]

	elseif (option_name == ZMQ_IDENTITY )
		option_value_ptr = Array(Uint8, 255) 
		sz = Array(Uint, 1)
		sz[1] = uint(length(option_value_ptr))
		rc=ccall(_jl_zmq_getsockopt, Int32, (Ptr{Void}, Int32, Ptr{Uint8}, Ptr{Uint}), socket.data, int32(option_name), option_value_ptr, sz)
		option_value_ptr[sz[1]+1] = 0
		if (rc != 0)  error ("ZMQ::getsockopt::$(jl_zmq_error_str())") ; end
		return cstring(convert(Ptr{Uint8}, option_value_ptr))::String

	else
		error("ZMQ::getsockopt::Unknown option type")
	end	
end 

function zmq_bind(socket::ZMQ_Socket, endpoint::String)
	rc=ccall(_jl_zmq_bind, Int32, (Ptr{Void}, Ptr{Uint8}), socket.data, cstring(endpoint))
	if (rc != 0) error ("ZMQ::bind::$(jl_zmq_error_str())"); end
end

function zmq_connect(socket::ZMQ_Socket, endpoint::String)
	rc=ccall(_jl_zmq_connect, Int32, (Ptr{Void}, Ptr{Uint8}), socket.data, cstring(endpoint))
	if (rc != 0) error ("ZMQ::connect::$(jl_zmq_error_str())"); end
end

zmq_send(socket::ZMQ_Socket, msg::String) = zmq_send(socket, msg, false, false) 
function zmq_send(socket::ZMQ_Socket, msg::String, noblock::Bool, sndmore::Bool)
	
	flag::Int32 = 0;
	if (noblock) flag = flag & ZMQ_NOBLOCK ; end
	if (sndmore) flag = flag & ZMA_SNDMORE ; end

	msg_t_ptr = Array(Uint8, sizeof(Uint)+ 2 + ZMQ_MAX_VSM_SIZE)
	rc=ccall(_jl_zmq_msg_init_size, Int32, (Ptr{Void}, Uint), msg_t_ptr, uint(length(msg)))
	if (rc != 0) error ("ZMQ::send::msg_init::$(jl_zmq_error_str())"); end
	
	msg_data_ptr = ccall(_jl_zmq_msg_data, Ptr{Void}, (Ptr{Void},) , msg_t_ptr)
	ccall(:memcpy, Ptr{Uint8},(Ptr{Uint8}, Ptr{Uint8}, Uint), msg_data_ptr, cstring(msg), uint(length(msg)))
	
	rc=ccall(_jl_zmq_send, Int32, (Ptr{Void}, Ptr{Void}, Int32), socket.data, msg_t_ptr, flag)
	if (rc != 0) error ("ZMQ::send::$(jl_zmq_error_str())"); end

	rc = ccall(_jl_zmq_msg_close, Int32, (Ptr{Void},), msg_t_ptr);
	if (rc != 0) error ("ZMQ::recv::msg_close::$(jl_zmq_error_str())"); end
end

zmq_recv(socket::ZMQ_Socket) = zmq_recv(socket, false)
function zmq_recv(socket::ZMQ_Socket, noblock::Bool)
	flag::Int32 = 0;
	if (noblock) flag = flag & ZMQ_NOBLOCK ; end
	
	msg_t_ptr = Array(Uint8, sizeof(Uint)+ 2 + ZMQ_MAX_VSM_SIZE)
	rc=ccall(_jl_zmq_msg_init, Int32, (Ptr{Void},), msg_t_ptr)
	if (rc != 0) error ("ZMQ::recv::msg_init::$(jl_zmq_error_str())"); end

	rc=ccall(_jl_zmq_recv, Int32, (Ptr{Void}, Ptr{Void}, Int32), socket.data, msg_t_ptr, flag)
	if (rc != 0) error ("ZMQ::recv::$(jl_zmq_error_str())"); end

	msg_data_ptr = ccall(_jl_zmq_msg_data, Ptr{Uint8}, (Ptr{Void},) , msg_t_ptr)
	msg_data_size::Uint = ccall(_jl_zmq_msg_size, Uint, (Ptr{Void},) , msg_t_ptr)

	result::String = ccall(:jl_pchar_to_string, Any, (Ptr{Uint}, Uint), msg_data_ptr, msg_data_size)
	rc = ccall(_jl_zmq_msg_close, Int32, (Ptr{Void},), msg_t_ptr);
	if (rc != 0) error ("ZMQ::recv::msg_close::$(jl_zmq_error_str())"); end
	return result
end

##Constants

#Socket Types
ZMQ_PAIR = 0
ZMQ_PUB = 1
ZMQ_SUB = 2
ZMQ_REQ = 3
ZMQ_REP = 4
ZMQ_DEALER = 5
ZMQ_ROUTER = 6
ZMQ_PULL = 7
ZMQ_PUSH = 8
ZMQ_XPUB = 9
ZMQ_XSUB = 10
ZMQ_XREQ = ZMQ_DEALER        
ZMQ_XREP = ZMQ_ROUTER        
ZMQ_UPSTREAM = ZMQ_PULL      
ZMQ_DOWNSTREAM = ZMQ_PUSH    


#Socket Options
ZMQ_HWM = 1
ZMQ_SWAP = 3
ZMQ_AFFINITY = 4
ZMQ_IDENTITY = 5
ZMQ_SUBSCRIBE = 6
ZMQ_UNSUBSCRIBE = 7
ZMQ_RATE = 8
ZMQ_RECOVERY_IVL = 9
ZMQ_MCAST_LOOP = 10
ZMQ_SNDBUF = 11
ZMQ_RCVBUF = 12
ZMQ_RCVMORE = 13
ZMQ_FD = 14
ZMQ_EVENTS = 15
ZMQ_TYPE = 16
ZMQ_LINGER = 17
ZMQ_RECONNECT_IVL = 18
ZMQ_BACKLOG = 19
ZMQ_RECOVERY_IVL_MSEC = 20  
ZMQ_RECONNECT_IVL_MAX = 21

#Send/Recv Options
ZMQ_NOBLOCK = 1
ZMQ_SNDMORE = 2

#IO Multiplexing
ZMQ_POLLIN = 1
ZMQ_POLLOUT = 2
ZMQ_POLLERR = 4

#Built in devices
ZMQ_STREAMER = 1
ZMQ_FORWARDER = 2
ZMQ_QUEUE = 3

#WARNING -- if this number changes in zmq.h, it needs to change below!
ZMQ_MAX_VSM_SIZE = 30


