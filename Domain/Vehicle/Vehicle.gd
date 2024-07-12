extends Item
class_name Vehicle;


var seats: Array[Object] = [];
@export var seatCount = 1;


func enterVehicle(character) -> bool:
	if (seats.size() < seatCount):
		seats.push_back(character);
		character.setVehicle(self);
		return true;
	
	return false;
