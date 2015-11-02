Server = require('socket.io')
io = new Server()
port = 3030



connectionNum = 0
players = {}
players['test_room'] = {}

rooms = io.on 'connection', (socket) ->
  connectionNum += 1
  console.log "[system] new connection: #{socket.id}"


  socket.on 'disconnect', ->
    connectionNum -= 1
    if players['test_room'][socket.id]
      rooms.in('test_room').emit('leave_player', socket.id)
      delete players['test_room'][socket.id]
    console.log "[system] disconnect: #{socket.id}(Total:#{connectionNum})"


  socket.on 'enter', (name, x, y, callback) ->
    console.log "enter: #{socket.id}(Total:#{connectionNum})"
    room_info = for id, info of players['test_room']
      { id: info.id, name: info.name, x: info.x, y: info.y }

    players['test_room'][socket.id] = { id: socket.id, name: name, x: x, y: y }

    rooms.in('test_room').emit('join_player', players['test_room'][socket.id])
    socket.join('test_room')
    callback(socket.id, room_info)


  socket.on 'move', (x, y) ->
    console.log "move: #{socket.id}(#{x},#{y})"
    players['test_room'][socket.id].x = x
    players['test_room'][socket.id].y = y
    rooms.in('test_room').emit('move', socket.id, x, y)


  socket.emit('ready')


io.listen(port)
console.log "===server start port:#{port}==="
