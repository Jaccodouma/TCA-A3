params ["_speed"];

// if !(ace_vehicles_isSpeedLimiter) then {
//     [player, vehicle player] call ace_vehicles_fnc_speedLimiter;
// };

ace_vehicles_isSpeedLimiter = false; // Set to false cause following function acts as a toggle 
[player, vehicle player] call ace_vehicles_fnc_speedLimiter;
ace_vehicles_speedlimit = _speed; 