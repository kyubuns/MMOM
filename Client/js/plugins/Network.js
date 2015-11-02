// Generated by CoffeeScript 1.9.1
(function() {
  var _Game_Interpreter_pluginCommand;

  _Game_Interpreter_pluginCommand = Game_Interpreter.prototype.pluginCommand;

  Game_Interpreter.prototype.pluginCommand = function(command, args) {
    if (command === 'Network') {
      switch (args[0]) {
        case "Connect":
          return $gameSystem.networkConnect();
        case "SendMove":
          return $gameSystem.sendMove();
        case "SendEnter":
          return $gameSystem.sendEnter(args[1]);
      }
    }
  };

  Game_System.prototype.networkConnect = function() {
    var socket;
    console.log("network connect start");
    $gameVariables.setValue(9, 0);
    socket = io.connect('http://localhost:3030', {
      transports: ["websocket"]
    });
    $gamePlayer.socket = socket;
    socket.on('connect', function() {
      console.log("connected!");
      return $gameVariables.setValue(9, 1);
    });
    socket.on('join_player', function(info) {
      return $gameSystem.joinPlayer(info);
    });
    socket.on('leave_player', function(networkId) {
      if ($gameSystem.networkPlayers[networkId]) {
        return delete $gameSystem.networkPlayers[networkId];
      }
    });
    socket.on('move', function(networkId, x, y) {
      if ($gameSystem.networkPlayers[networkId]) {
        $gameSystem.networkPlayers[networkId].x = x;
        return $gameSystem.networkPlayers[networkId].y = y;
      }
    });
    return console.log("network connect finish");
  };

  Game_System.prototype.joinPlayer = function(info) {
    return $gameMap.getEventDataFrom(1, 1, function(eventData) {
      var gameEvent;
      gameEvent = $gameMap.addEventAt(eventData, info['x'], info['y'], true);
      MVC.accessor(gameEvent, 'networkId');
      gameEvent.networkId = info['id'];
      return $gameSystem.networkPlayers[info['id']] = info;
    });
  };

  Game_System.prototype.getNetworkPlayerInfo = function(networkId) {
    var info;
    info = $gameSystem.networkPlayers[networkId];
    if (info) {
      $gameVariables.setValue(10, 1);
      $gameVariables.setValue(11, info['x']);
      return $gameVariables.setValue(12, info['y']);
    } else {
      return $gameVariables.setValue(10, 0);
    }
  };

  Game_System.prototype.sendMove = function() {
    if (!$gamePlayer.socket) {
      return;
    }
    return $gamePlayer.socket.emit('move', $gamePlayer.x, $gamePlayer.y);
  };

  Game_System.prototype.sendEnter = function(mapId) {
    if (!$gamePlayer.socket) {
      return;
    }
    return $gamePlayer.socket.emit('enter', 'dummy', mapId, $gamePlayer.x, $gamePlayer.y, function(id, infos) {
      var i, info, len, results;
      console.log("entered");
      $gamePlayer.networkId = id;
      $gameSystem.networkPlayers = {};
      results = [];
      for (i = 0, len = infos.length; i < len; i++) {
        info = infos[i];
        results.push($gameSystem.joinPlayer(info));
      }
      return results;
    });
  };

}).call(this);
