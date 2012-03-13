load ("jl/zmq.jl")

ctx = zmq_init(1)
responder = zmq_socket(ctx, ZMQ_REP)
zmq_bind(responder, "tcp://*:5555")

while true
	request = zmq_recv(responder)
	print ("Recieved request: [$(request)] \n")
	sleep (1)
	zmq_send(responder, "World")
end