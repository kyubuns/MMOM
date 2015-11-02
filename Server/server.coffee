Server = require('socket.io')
io = new Server()
port = 3030

io.on 'connection', (socket) ->
  console.log "[system] new connection: #{socket.id}"
  socket.emit('ready')

io.listen(port)
console.log "===server start port:#{port}==="
