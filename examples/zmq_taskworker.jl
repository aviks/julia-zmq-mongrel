load ("jl/zmq.jl")

ctx = zmq_init(1)
reciever = zmq_socket(ctx, ZMQ_PULL)
zmq_connect(reciever, "tcp://localhost:5557")

sender = zmq_socket(ctx, ZMQ_PUSH);
zmq_connect(sender, "tcp://localhost:5558")

print ("Worker is now listening \n")
total_msec = 0
while true
	str = zmq_recv(reciever)
	print(" [$str] ")
	sleep(int(str)/1000)
	zmq_send(sender, " ")
end

zmq_close(reciever)
zmq_close(sender)
zmq_term(ctx)