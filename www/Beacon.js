
var exec = require('cordova/exec');

/**
 * Constructor
 */
function Beacon() {}

Beacon.prototype.addRegion = function(success, fail, params) {
  exec(success, fail, "Beacon", "addBeaconRegion", [params || {}]);
};

Beacon.prototype.removeRegion = function(success, fail, params) {
  exec(success, fail, "Beacon", "removeBeaconRegion", [params || {}]);
};
               
Beacon.prototype.setHost = function(success, fail, params) {
   exec(success, fail, "Beacon", "setHost", [params || {}]);
};
               
Beacon.prototype.setToken = function(success, fail, params) {
   exec(success, fail, "Beacon", "setToken", [params || {}]);
};

/*
Params:
NONE
*/
Beacon.prototype.getWatchedRegionIds = function(success, fail) {
  exec(success, fail, "Beacon", "getWatchedBeaconRegionIds", []);
};



// exports
var Beacon = new Beacon();
module.exports = Beacon;
// });
