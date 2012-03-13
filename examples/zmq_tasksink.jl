load ("jl/zmq.jl")

ctx = zmq_init(1)
reciever = zmq_socket(ctx, ZMQ_PULL)
zmq_bind(reciever, "tcp://*:5558")

#Wait for start of batch
zmq_recv(reciever)

start_time = time()
print("\n") #Clear the line
for i=1:100
	zmq_recv(reciever)
	if (rem(i,10) == 0 )
		print (":")
	else
		print (".")
	end
	flush(stdout_stream)
end

print("\nTotal time elapsed: $((time()-start_time)*1000) msec \n")
total_msec = 0

zmq_close(reciever)

zmq_term(ctx)