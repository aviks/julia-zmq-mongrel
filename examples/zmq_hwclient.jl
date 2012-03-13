load ("jl/zmq.jl")

ctx = zmq_init(1)
requester = zmq_socket(ctx, ZMQ_REQ)
zmq_connect(requester, "tcp://localhost:5555")

for i=1:8
	print ("Sending request $i \n")
	zmq_send(requester, "Hello")

	reply = zmq_recv (requester)
	print ("Recieved reply $i : [$(reply)] \n")
end	