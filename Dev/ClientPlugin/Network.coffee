_Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand
Game_Interpreter.prototype.pluginCommand = (command, args) ->
  if command == 'Network'
    switch args[0]
      when "Connect"
        $gameSystem.networkConnect()
      when "SendMove"
        $gameSystem.sendMove()
      when "SendEnter"
        $gameSystem.sendEnter(args[1])
      when "OpenURL"
        $gameSystem.openUrl(args[1])


Game_System.prototype.networkConnect = ->
  console.log("network connect start")
  $gameVariables.setValue(9, 0)
  socket = io.connect('http://localhost:3030', { transports:["websocket"], forceNew: true })
  $gamePlayer.socket = socket

  socket.on 'connect', ->
    console.log("connected!")
    $gameVariables.setValue(9, 1)

  socket.on 'join_player', (info) ->
    $gameSystem.joinPlayer(info)

  socket.on 'leave_player', (networkId) ->
    delete $gameSystem.networkPlayers[networkId] if $gameSystem.networkPlayers[networkId]

  socket.on 'move', (networkId, x, y) ->
    if $gameSystem.networkPlayers[networkId]
      $gameSystem.networkPlayers[networkId].x = x
      $gameSystem.networkPlayers[networkId].y = y

  console.log("network connect finish")


Game_System.prototype.joinPlayer = (info) ->
  $gameMap.getEventDataFrom 1, 1, (eventData) ->
    gameEvent = $gameMap.addEventAt(eventData, info['x'], info['y'], true)
    MVC.accessor(gameEvent, 'networkId')
    gameEvent.networkId = info['id']
    $gameSystem.networkPlayers[info['id']] = info


Game_System.prototype.getNetworkPlayerInfo = (networkId) ->
  info = $gameSystem.networkPlayers[networkId]
  if info
    $gameVariables.setValue(10, 1)
    $gameVariables.setValue(11, info['x'])
    $gameVariables.setValue(12, info['y'])
  else
    $gameVariables.setValue(10, 0)


Game_System.prototype.sendMove = ->
  unless $gamePlayer.socket
    return

  $gamePlayer.socket.emit('move', $gamePlayer.x, $gamePlayer.y)


Game_System.prototype.sendEnter = (mapId) ->
  unless $gamePlayer.socket
    return

  $gamePlayer.socket.emit('enter', 'dummy', mapId, $gamePlayer.x, $gamePlayer.y, (id, infos) ->
    console.log("entered")
    $gamePlayer.networkId = id
    $gameSystem.networkPlayers = {}
    $gameSystem.joinPlayer(info) for info in infos
  )

Game_System.prototype.openUrl = (url) ->
  window.open(url, '_blank')



_Scene_Title_create = Scene_Title.prototype.create
Scene_Title.prototype.create = ->
  _Scene_Title_create.call(this)
  if $gamePlayer.socket
    console.log('release')
    $gamePlayer.socket.disconnect()
    $gamePlayer.socket = null


_Game_Temp_setDestination = Game_Temp.prototype.setDestination
Game_Temp.prototype.setDestination = (x, y) ->
  _Game_Temp_setDestination.call(this, x, y)
  width = $dataMap.width
  height = $dataMap.height
  z = 0
  index = [(z * height + y) * width + x]
  $dataMap.data[index] = 100
