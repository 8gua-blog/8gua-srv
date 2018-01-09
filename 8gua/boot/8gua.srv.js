#!/usr/bin/env node
(function() {
  var fork, fork_run, path;

  ({fork} = require('child_process'));

  path = require("path");

  fork_run = function(js) {
    var forked, run;
    forked = void 0;
    run = function() {
      forked = fork(path.join(__dirname, js + '.js'));
      return forked.on('exit', (code) => {
        if (0 === code) {
          return run();
        }
      });
    };
    return run();
  };

  module.exports = function() {
    return fork_run('fastify');
  };

  // fork_run 'ws'

  // setTimeout(
  //     =>
  //         forked.send 'EXIT'
  //     2000
  // )
  if (require.main === module) {
    module.exports();
  }

}).call(this);
