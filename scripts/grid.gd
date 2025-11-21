extends Node2D

const MAX_SHIELD = 15
class MatchPlayer:
	var health: int = 18
	var shield: int = 0
	var reds: int = 0
	var greens: int = 0
	var blues: int = 0
	var moves: int = 3

var turn_time := 30
var turn_timer_running := true
var timer_label
var turn_indicator: Sprite2D
var indicator_offset := Vector2(0, -120)

var p0_labels = {}
var p1_labels = {}



var players = [MatchPlayer.new(), MatchPlayer.new()]
var current_player_index = 0

#state machine
enum {wait,move}
var state;

#grid vars
@export var width:int;
@export var height:int;
@export var x_start:int;
@export var y_start:int;
@export var offset:int;
@export var y_offset:int;

#power vars
@export var p_width:int
@export var p_height:int
@export var p_x_start:int
@export var p_y_start:int
@export var p_offset:int
@export var p_y_offset:int
@export var power_spaces_p0: PackedVector2Array
@export var power_spaces_p1: PackedVector2Array

#player vars
@export var player0_spawn_position: Vector2 = Vector2(100, 100)
@export var player1_spawn_position: Vector2 = Vector2(900, 100)
var player0_node: Node2D
var player1_node: Node2D

var possible_players = [
	preload("res://player_knight.tscn"),
	preload("res://player_hunter.tscn")
]

var possible_powers = [
	preload("res://health_power.tscn"),
	preload("res://attack_power.tscn"),
	preload("res://move_power.tscn"),
	preload("res://shield_power.tscn")
]

var possible_pieces = [
	preload("res://yellow_pieces.tscn"),
	preload("res://green_pieces.tscn"),
	preload("res://pink_pieces.tscn"),
	preload("res://orange_pieces.tscn"),
	preload("res://blu_piece.tscn"),
	preload("res://yellow_2_pieces.tscn")
];


var all_powers = [];
var all_pieces = [];

#swap back pieces
var piece_1=null;
var piece_2=null;
var last_place = Vector2(0,0);
var last_direction = Vector2(0,0);
var move_checked = false;

var first_click = Vector2(0,0);
var first_click_p = Vector2(0,0);
var final_click = Vector2(0,0);
var final_click_p = Vector2(0,0);
var controlling = false;

#effects
var particle_effect = preload("res://particleEffect.tscn")

#check power spots
func all_power_positions(place: Vector2) -> bool:
	return power_spaces_p0.has(place) or power_spaces_p1.has(place)

func current_player_power_positions(place: Vector2) -> bool:
	if current_player_index == 0:
		return power_spaces_p0.has(place)
	else:
		return power_spaces_p1.has(place)

func _ready():
	#$winner.hide()
	state = move;
	randomize();
	all_pieces = make2darray();
	all_powers = make2darray_power();
	spawn_pieces();
	spawn_players();
	if Global.gamemode == 1:
		spawn_powers();
	
	turn_indicator = get_parent().get_node("TurnIndicator")
	turn_indicator.position = player0_node.position + indicator_offset
	turn_indicator.show()
	
	var stats_root = get_parent()
	timer_label = get_parent().get_node("TimerLabel")
	timer_label.text = str(turn_time)
	
	# Get references to Player 0's labels
	p0_labels.moves   = stats_root.get_node("player0/moves_Label")
	p0_labels.hp      = stats_root.get_node("player0/HP_Label")
	p0_labels.shield  = stats_root.get_node("player0/shield_Label")
	p0_labels.reds    = stats_root.get_node("player0/reds_Label")
	p0_labels.greens  = stats_root.get_node("player0/greens_Label")
	p0_labels.blues   = stats_root.get_node("player0/blues_Label")
	p0_labels.wins   = stats_root.get_node("player0/wins_Label")

	# Get references to Player 1's labels
	p1_labels.moves   = stats_root.get_node("player1/moves_Label")
	p1_labels.hp      = stats_root.get_node("player1/HP_Label")
	p1_labels.shield  = stats_root.get_node("player1/shield_Label")
	p1_labels.reds    = stats_root.get_node("player1/reds_Label")
	p1_labels.greens  = stats_root.get_node("player1/greens_Label")
	p1_labels.blues   = stats_root.get_node("player1/blues_Label")
	p1_labels.wins   = stats_root.get_node("player1/wins_Label")
	update_stats()


func update_stats():
	var p0 = players[0]
	var p1 = players[1]
	
	var active_color = Color(0, 1, 0)     # green
	var inactive_color = Color(0, 0, 0)   # white

	p0_labels.moves.text  = "Moves:  %d" % p0.moves
	p0_labels.hp.text     = "HP:     %d" % p0.health
	p0_labels.shield.text = "Shield: %d" % p0.shield
	p0_labels.reds.text   = "Reds:   %d" % p0.reds
	p0_labels.greens.text = "Greens: %d" % p0.greens
	p0_labels.blues.text  = "Blues:  %d" % p0.blues
	p0_labels.wins.text = "Wins: %d" % Global.player0wins

	p1_labels.moves.text  = "Moves:  %d" % p1.moves
	p1_labels.hp.text     = "HP:     %d" % p1.health
	p1_labels.shield.text = "Shield: %d" % p1.shield
	p1_labels.reds.text   = "Reds:   %d" % p1.reds
	p1_labels.greens.text = "Greens: %d" % p1.greens
	p1_labels.blues.text  = "Blues:  %d" % p1.blues
	p1_labels.wins.text = "Wins: %d" % Global.player1wins
	
	if current_player_index == 0:
		_set_labels_color(p0_labels, active_color)
		_set_labels_color(p1_labels, inactive_color)
	else:
		_set_labels_color(p0_labels, inactive_color)
		_set_labels_color(p1_labels, active_color)
	
	if p0.health <= 0 or p1.health <= 0:
		state = wait
		var winner_index = 0 if p1.health <= 0 else 1
		if winner_index == 0:
			Global.player0wins += 1
		else:
			Global.player1wins += 1
		turn_timer_running = false
		var winner_text = "Player %d Wins!" % (winner_index+1)
		var popup = get_parent().get_node("winner")
		popup.get_node("Label").text = winner_text
		popup.set_exclusive(true)
		popup.show()


func _set_labels_color(labels, color):
	labels.moves.modulate = color



func make2darray():
	var array =[];
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null);
	return array

func make2darray_power():
	var array =[];
	for i in p_width:
		array.append([]);
		for j in p_height:
			array[i].append(null);
	return array

func spawn_players():
	if Global.player0class >= 0 and Global.player0class < possible_players.size():
		var player0_scene = possible_players[Global.player0class]
		player0_node = player0_scene.instantiate()
		player0_node.position = player0_spawn_position
		add_child(player0_node)
	else:
		push_warning("Invalid player0class: %d" % Global.player0class)

	if Global.player1class >= 0 and Global.player1class < possible_players.size():
		var player1_scene = possible_players[Global.player1class]
		player1_node = player1_scene.instantiate()
		player1_node.position = player1_spawn_position
		player1_node.scale.x = -abs(player1_node.scale.x)
		add_child(player1_node)
	else:
		push_warning("Invalid player1class: %d" % Global.player1class)

func spawn_pieces():
	for i in width:
		for j in height:
			var rand = floor(randf_range(0,possible_pieces.size()));
			var piece = possible_pieces[rand].instantiate();
			var loops = 0;
			while(match_at(i,j,piece.color)) && loops <100:
				rand = floor(randf_range(0,possible_pieces.size()));
				loops+=1;
				piece = possible_pieces[rand].instantiate();
			
			add_child(piece);
			piece.position = grid_2_pixel(i,j);
			all_pieces[i][j] = piece;

func spawn_powers():
	for i in p_width:
		for j in p_height:
			if all_power_positions(Vector2(i,j)):
				var rand = randi_range(0, possible_powers.size()-1)
				var power = possible_powers[rand].instantiate()
				add_child(power)
				power.position = grid_2_pixel_power(i, j)
				all_powers[i][j] = power

func match_at(i , j , color):
	if i > 1:
		if all_pieces[i-1][j] != null && all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].color == color && all_pieces[i-2][j].color == color:
				return true;
	if j > 1:
		if all_pieces[i][j-1] != null && all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].color == color && all_pieces[i][j-2].color == color:
				return true;


func grid_2_pixel(column,row):
	var new_x = x_start+offset*column;
	var new_y = y_start+ -offset*row;
	return Vector2(new_x,new_y);

func grid_2_pixel_power(column,row):
	var new_x = p_x_start+p_offset*column;
	var new_y = p_y_start+ -p_offset*row;
	return Vector2(new_x,new_y);

func pix_2_grid(pixel_x,pixel_y):
	var new_x = round((pixel_x - x_start)/offset);
	var new_y = round((pixel_y - y_start)/-offset);
	return Vector2(new_x,new_y);

func pix_2_grid_power(pixel_x,pixel_y):
	var new_x = round((pixel_x - p_x_start)/p_offset);
	var new_y = round((pixel_y - p_y_start)/-p_offset);
	return Vector2(new_x,new_y);

func is_in_grid(grid_pos):
	if grid_pos.x >= 0 && grid_pos.x < width:
		if grid_pos.y >= 0 && grid_pos.y < height:
			return true;
	return false;

func is_in_power(grid_pos):
	if grid_pos.x >= 0 && grid_pos.x < p_width:
		if grid_pos.y >= 0 && grid_pos.y < p_height:
			return true;
	return false;

func click_power():
	if Input.is_action_just_pressed("UI_click"):
		if current_player_power_positions(pix_2_grid_power(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_click_p = pix_2_grid_power(get_global_mouse_position().x, get_global_mouse_position().y)
	if Input.is_action_just_released("UI_click"):
		final_click_p = get_global_mouse_position()
		var grid_pos = pix_2_grid_power(final_click_p.x, final_click_p.y)
		if first_click_p == grid_pos and current_player_power_positions(grid_pos):
			activate_power(all_powers[grid_pos.x][grid_pos.y])
			pass

func click_input():
	if Input.is_action_just_pressed("UI_click"):
		if is_in_grid(pix_2_grid(get_global_mouse_position().x,get_global_mouse_position().y)):
			first_click = pix_2_grid(get_global_mouse_position().x,get_global_mouse_position().y);
			controlling = true;
		#print(grid_pos);
	if Input.is_action_just_released("UI_click"):
		final_click = get_global_mouse_position();
		var grid_pos = pix_2_grid(final_click.x,final_click.y);
		if is_in_grid(pix_2_grid(get_global_mouse_position().x,get_global_mouse_position().y)) && controlling:
			controlling = false;
			final_click = pix_2_grid(get_global_mouse_position().x,get_global_mouse_position().y);
			click_difference(first_click, final_click);
			
		
func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row];
	var other_piece = all_pieces[column + direction.x][row + direction.y];
	if first_piece != null && other_piece !=null:
		store_info(first_piece,other_piece,Vector2(column,row),direction);
		state = wait;
		all_pieces[column][row] = other_piece;
		all_pieces[column + direction.x][row + direction.y] = first_piece;
		first_piece.move(grid_2_pixel(column + direction.x, row + direction.y));
		other_piece.move(grid_2_pixel(column,row));
		if !move_checked:
			find_matches();

func store_info(first_piece,other_piece,place,direction):
	piece_1 = first_piece;
	piece_2 = other_piece;
	last_place = place;
	last_direction = direction;

func swap_back():
	if piece_1 != null && piece_2 != null:
		swap_pieces(last_place.x,last_place.y,last_direction);
	state = move;
	move_checked = false;

func click_difference(grid_1,grid_2):
	var difference = grid_2 - grid_1;
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(1,0));
		elif difference.x < 0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(-1,0));
	elif abs(difference.y) > abs(difference.x):
		if difference.y >0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(0,1));
		elif difference.y < 0:
			swap_pieces(grid_1.x,grid_1.y,Vector2(0,-1));

func _process(delta):
	if turn_indicator:
		turn_indicator.position.y += sin(Time.get_ticks_msec() / 200.0) * 0.2
	if state == move:
		click_input();
		if Global.gamemode == 1:
			click_power();

func find_matches():
	for i in width:
		for j in height:
			if !is_piece_null(i,j):
				var current_color = all_pieces[i][j].color;
				if i >0 && i < width - 1:
					if !is_piece_null(i-1,j) && !is_piece_null(i+1,j):
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							match_and_dim(all_pieces[i-1][j]);
							match_and_dim(all_pieces[i][j]);
							match_and_dim(all_pieces[i+1][j]);
				if j >0 && j < height - 1:
					if !is_piece_null(i,j-1) && !is_piece_null(i,j+1):
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							match_and_dim(all_pieces[i][j-1]);
							match_and_dim(all_pieces[i][j]);
							match_and_dim(all_pieces[i][j+1]);
	get_parent().get_node("destroy_timer").start();

func activate_power(item):
	match item.type:
		"health":
			if players[current_player_index].reds >= 3 and players[current_player_index].greens >= 6 and players[current_player_index].blues >= 3:
				item.matched = true
				players[current_player_index].health += 3
				players[current_player_index].reds -= 3
				players[current_player_index].greens -= 6
				players[current_player_index].blues -= 3
				item.dim()
			else:
				item.not_possible()
		"attack":
			if players[current_player_index].reds >= 6 and players[current_player_index].greens >= 3 and players[current_player_index].blues >= 3:
				item.matched = true
				apply_damage(players[1 - current_player_index], 3)
				players[current_player_index].reds -= 6
				players[current_player_index].greens -= 3
				players[current_player_index].blues -= 3
				item.dim()
			else:
				item.not_possible()
		"shield":
			if players[current_player_index].reds >= 3 and players[current_player_index].greens >= 3 and players[current_player_index].blues >= 6:
				item.matched = true
				add_shield(players[current_player_index], 3)
				players[current_player_index].reds -= 3
				players[current_player_index].greens -= 3
				players[current_player_index].blues -= 6
				item.dim()
			else:
				item.not_possible()
		"move":
			if players[current_player_index].reds >= 6 and players[current_player_index].greens >= 6 and players[current_player_index].blues >= 6:
				item.matched = true
				players[current_player_index].moves += 1
				players[current_player_index].reds -= 6
				players[current_player_index].greens -= 6
				players[current_player_index].blues -= 6
				item.dim()
			else:
				item.not_possible()
	update_stats();
	
	await get_tree().create_timer(0.5).timeout
	destroy_power()


func is_piece_null(column,row):
	if all_pieces[column][row] == null:
		return true;
	return false;

func match_and_dim(item):
	item.matched = true;
	item.dim();
	
	match item.color:
		"yellow":
			apply_damage(players[1 - current_player_index], 1)
		"yellow2":
			apply_damage(players[1 - current_player_index], 2)
		"orange":
			add_shield(players[current_player_index], 1)
		"pink":
			players[current_player_index].reds += 1
		"green":
			players[current_player_index].greens += 1
		"blue":
			players[current_player_index].blues += 1

func add_shield(player: MatchPlayer, amount: int):
	player.shield = min(player.shield + amount, MAX_SHIELD)

func apply_damage(player: MatchPlayer, damage: int):
	var player_index = players.find(player)

	if player_index == -1:
		push_warning("Player not found in player list.")
		return
	match player_index:
		0:
			if player0_node:
				player0_node.damaged()
		1:
			if player1_node:
				player1_node.damaged()
	if player.shield >= damage:
		player.shield -= damage
	else:
		var leftover = damage - player.shield
		player.shield = 0
		player.health = max(player.health - leftover, 0)

func destroy_power():
	var was_matched = false
	for i in p_width:
		for j in p_height:
			if all_powers[i][j] != null and all_powers[i][j].matched:
				was_matched = true
				all_powers[i][j].queue_free()
				all_powers[i][j] = null
	#this part makes refill stuff. i didnt bother making a new function for it
	for i in p_width:
		for j in p_height:
			if all_powers[i][j] == null and all_power_positions(Vector2(i,j)):
				var rand = randi_range(0, possible_powers.size()-1)
				var power = possible_powers[rand].instantiate()
				add_child(power)
				power.position = grid_2_pixel_power(i, j)
				all_powers[i][j] = power
				#make_effect(particle_effect, i-3, j)

func destroy_matched():
	var was_matched = false;
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					was_matched = true;
					all_pieces[i][j].queue_free();
					all_pieces[i][j] = null;
					make_effect(particle_effect,i,j)
	move_checked = true;
	if was_matched:
		get_parent().get_node("collapse_timer").start();
	else:
		swap_back();

func make_effect(effect,column,row):
	var current = effect.instantiate()
	current.position = grid_2_pixel(column,row)
	add_child(current)

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				for k in range(j+1,height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_2_pixel(i,j));
						all_pieces[i][j] = all_pieces[i][k];
						all_pieces[i][k] = null;
						break;
	get_parent().get_node("refill_timer").start();

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				var rand = floor(randf_range(0,possible_pieces.size()));
				var piece = possible_pieces[rand].instantiate();
				var loops = 0;
				while(match_at(i,j,piece.color)) && loops <100:
					rand = floor(randf_range(0,possible_pieces.size()));
					loops+=1;
					piece = possible_pieces[rand].instantiate();
				
				add_child(piece);
				piece.position = grid_2_pixel(i,j - y_offset);
				piece.move(grid_2_pixel(i,j));
				all_pieces[i][j] = piece;
	after_refill()

func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i,j,all_pieces[i][j].color):
					find_matches();
					get_parent().get_node("destroy_timer").start();
					return;
	state= move;
	move_checked = false;
	turn_time = 30
	timer_label.text = str(turn_time)
	
	# Decrease moves
	players[current_player_index].moves -= 1

	# Switch player if out of moves
	if players[current_player_index].moves <= 0:
		players[current_player_index].moves += 3
		current_player_index = 1 - current_player_index  # Toggle
		update_turn_indicator()
		
		#passive_stats()
		#players[current_player_index].moves += 3
		
	update_stats();

func passive_stats():
	if current_player_index == 0:
		if Global.player0class == 0 && players[current_player_index].health < 12:
			add_shield(players[current_player_index], 3)
		elif Global.player0class == 1 && players[current_player_index].health < 12:
			players[current_player_index].health += 3
		elif Global.player0class == 2 && players[current_player_index].health < 12:
			players[current_player_index].moves += 1
		elif Global.player0class == 3 && players[current_player_index].health < 12:
			players[current_player_index].reds += 1
			players[current_player_index].greens += 1
			players[current_player_index].blues += 1
	elif current_player_index == 1:
		if Global.player1class == 0 && players[current_player_index].health < 12:
			add_shield(players[current_player_index], 3)
		elif Global.player1class == 1 && players[current_player_index].health < 12:
			players[current_player_index].health += 3
		elif Global.player1class == 2 && players[current_player_index].health < 12:
			players[current_player_index].moves += 1
		elif Global.player1class == 3 && players[current_player_index].health < 12:
			players[current_player_index].reds += 1
			players[current_player_index].greens += 1
			players[current_player_index].blues += 1

func _on_destroy_timer_timeout():
	destroy_matched();


func _on_collapse_timer_timeout():
	collapse_columns();


func _on_refill_timer_timeout():
	refill_columns();


func _on_restart_button_pressed():
	get_tree().reload_current_scene()


func _on_reset_button_pressed():
	# Decrease moves
	players[current_player_index].moves -= 1

	# Switch player if out of moves
	if players[current_player_index].moves <= 0:
		players[current_player_index].moves += 3
		current_player_index = 1 - current_player_index  # Toggle
		
		update_turn_indicator()
		turn_time = 30
		timer_label.text = str(turn_time)
		#passive_stats()
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	all_pieces = make2darray()
	spawn_pieces()
	
	update_stats()

func update_turn_indicator():
	if current_player_index == 0:
		turn_indicator.position = player0_node.position + indicator_offset
	else:
		turn_indicator.position = player1_node.position + indicator_offset

func _on_button_pressed():
	get_tree().change_scene_to_file("res://game_menu.tscn")


func _on_turn_timer_timeout():
	if !turn_timer_running:
		return
	turn_time -= 1
	timer_label.text = str(turn_time)
	if turn_time <= 0:
		apply_damage(players[current_player_index], 3)
		update_stats()
		turn_time = 30
		timer_label.text = str(turn_time)
