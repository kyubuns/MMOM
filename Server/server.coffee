Server = require('socket.io')
io = new Server()
port = 3030



connectionNum = 0
players = {}

rooms = io.on 'connection', (socket) ->
  connectionNum += 1
  console.log "[system] new connection: #{socket.id}"


  socket.on 'disconnect', ->
    connectionNum -= 1
    if socket.currentMapId && players[socket.currentMapId][socket.id]
      rooms.in(socket.currentMapId).emit('leave_player', socket.id)
      delete players[socket.currentMapId][socket.id]
    console.log "[system] disconnect: #{socket.id}(Total:#{connectionNum})"


  socket.on 'enter', (name, mapId, x, y, callback) ->
    console.log "enter: #{socket.id} -> #{mapId} (Total:#{connectionNum})"

    #前の部屋から追い出す
    if socket.currentMapId && players[socket.currentMapId][socket.id]
      socket.leave(socket.currentMapId)
      rooms.in(socket.currentMapId).emit('leave_player', socket.id)
      delete players[socket.currentMapId][socket.id]

    #入れる
    socket.currentMapId = mapId
    players[mapId] = {} unless players[mapId]
    room_info = for id, info of players[mapId]
      { id: info.id, name: info.name, x: info.x, y: info.y }

    players[mapId][socket.id] = { id: socket.id, name: name, x: x, y: y }

    rooms.in(mapId).emit('join_player', players[mapId][socket.id])
    socket.join(mapId)
    callback(socket.id, room_info)


  socket.on 'move', (x, y) ->
    console.log "move: #{socket.id}[#{socket.currentMapId}](#{x},#{y})"
    return unless socket.currentMapId
    players[socket.currentMapId][socket.id].x = x
    players[socket.currentMapId][socket.id].y = y
    rooms.in(socket.currentMapId).emit('move', socket.id, x, y)


  socket.emit('ready')


io.listen(port)
console.log "===server start port:#{port}==="
