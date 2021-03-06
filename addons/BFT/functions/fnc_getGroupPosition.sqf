#include "script_component.hpp"

params ["_group"];

fnc_weightedAverage = {
	params ["_group"];

	_position = position leader _group;
	_weight = 3 * (count units _group); // Starting weight, amount of times we count the leader position.  
	{
		// If unit is within 500m, ignore them from position calculation
		if ((_x distance2D (leader group _x)) > 500) then {continue};

		// Ignore leader, we have their position already
		if (_x == leader group _x) then {continue};
		
		// Each unit in the group 'pulls' the marker towards them
		// The strength of the pull decreases 
		_position = [
			// ((running average) + (current position)) ... (averaged)
			(((_position select 0) * _weight) + ((position _x) select 0)) / (_weight + 1),
			(((_position select 1) * _weight) + ((position _x) select 1)) / (_weight + 1)
		];

		// Increase weight - as we've included one more unit now 
		_weight = _weight + 1; 
	} forEach units _group;

	_position;
};


_position = position leader _group; 

// Get current position 
switch (GVAR(groupMarkers_trackingMode)) do 
{
	case "weightedAverage": {
		_position = [_group] call fnc_weightedAverage;
	};
};

// Add current position to group variable 
_positions = _group getVariable ["BFT_Trail_Positions", []];
_positions = [_position] + _positions; // Add to the front of the array 
_positions = _positions select [0, round GVAR(groupMarkers_trailingCount)]; // Limit the size to trailing weight. 
_group setVariable ["BFT_Trail_Positions", _positions]; // Update variable

// Calculate new position if we're trailing 
switch (GVAR(groupMarkers_trailingMode)) do {
	case "weightedAverage": {
		// Calculate new position 
		_weight = 1; 
		_totalWeight = 1; 
		_position = [] + _positions select 0;
		{
			// Skip the first one
			if (_forEachIndex == 0) then {continue;};
			_weight = _weight * GVAR(groupMarkers_trailingWeight);

			_position = [
				(((_position select 0) * _totalWeight) + ((_x select 0) * _weight)) / (_totalWeight + _weight),
				(((_position select 1) * _totalWeight) + ((_x select 1) * _weight)) / (_totalWeight + _weight)
			];

			_totalWeight = _totalWeight + _weight; 
		} forEach _positions;
	}; 
	case "delayed": {
		_position = _positions select (count _positions -1);
	};
	case "projected": {
		// Conclusion: its complicated.
		// Kinda ok for vehicles, but doesnt work for groups on foot
		_position = [] + _positions select (count _positions -1);
		_velocity = velocity leader _group;
		if(count _positions > 1) then {
			_pos2 = _positions select (count _positions -2);
			_velocity = [
				(_pos2 select 0) - (_position select 0), 
				(_pos2 select 1) - (_position select 1)
			];
		};
		_dx = (round GVAR(groupMarkers_updateDelay)) * (_velocity select 0) /* * (GVAR(groupMarkers_trailingCount) - 1)*/;
		_dy = (round GVAR(groupMarkers_updateDelay)) * (_velocity select 1) /* * (GVAR(groupMarkers_trailingCount) - 1)*/;

		_position = [
			(_position select 0) + _dx,
			(_position select 1) + _dy
		];
	};
};

// Return position
_position