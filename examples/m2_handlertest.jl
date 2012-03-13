load ("jl/mongrel2.jl")

DEBUG=true

t = m2_run_server("6DFF1523-C091-49B8-B635-598640E864B3", "tcp://127.0.0.1:9997", "tcp://127.0.0.1:9996")
while true
	(conn, req) = consume (t) 	
	response = "<html><body>Sender: $(req.sender_id)<br>ConnectionId: $(req.connection_id)<br>Path: $(req.path)<br>Headers: $(string(req.headers))<br> Body: $(req.body)</html></body>"

	if m2_is_disconnected(req); continue; end
	m2_reply_http(conn, req, response)


end