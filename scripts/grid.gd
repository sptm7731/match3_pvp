extends Node2D

const MAX_SHIELD = 15
class MatchPlayer:
	var health: int = 45
	var shield: int = 0
	var reds: int = 0
	var greens: int = 0
	var blues: int = 0
	var moves: int = 3


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

var possible_pieces = [
	preload("res://yellow_pieces.tscn"),
	preload("res://green_pieces.tscn"),
	preload("res://pink_pieces.tscn"),
	preload("res://orange_pieces.tscn"),
	preload("res://blu_piece.tscn"),
	preload("res://yellow_2_pieces.tscn")
];

var all_pieces = [];

#swap back pieces
var piece_1=null;
var piece_2=null;
var last_place = Vector2(0,0);
var last_direction = Vector2(0,0);
var move_checked = false;

var first_click = Vector2(0,0);
var final_click = Vector2(0,0);
var controlling = false;



func _ready():
	state = move;
	randomize();
	all_pieces = make2darray();
	spawn_pieces();
	
	var stats_root = get_parent()
	
	# Get references to Player 0's labels
	p0_labels.moves   = stats_root.get_node("player0/moves_Label")
	p0_labels.hp      = stats_root.get_node("player0/HP_Label")
	p0_labels.shield  = stats_root.get_node("player0/shield_Label")
	p0_labels.reds    = stats_root.get_node("player0/reds_Label")
	p0_labels.greens  = stats_root.get_node("player0/greens_Label")
	p0_labels.blues   = stats_root.get_node("player0/blues_Label")

	# Get references to Player 1's labels
	p1_labels.moves   = stats_root.get_node("player1/moves_Label")
	p1_labels.hp      = stats_root.get_node("player1/HP_Label")
	p1_labels.shield  = stats_root.get_node("player1/shield_Label")
	p1_labels.reds    = stats_root.get_node("player1/reds_Label")
	p1_labels.greens  = stats_root.get_node("player1/greens_Label")
	p1_labels.blues   = stats_root.get_node("player1/blues_Label")
	update_stats()


func update_stats():
	var p0 = players[0]
	var p1 = players[1]
	
	var active_color = Color(0, 1, 0)     # green
	var inactive_color = Color(1, 1, 1)   # white

	p0_labels.moves.text  = "Moves:  %d" % p0.moves
	p0_labels.hp.text     = "HP:     %d" % p0.health
	p0_labels.shield.text = "Shield: %d" % p0.shield
	p0_labels.reds.text   = "Reds:   %d" % p0.reds
	p0_labels.greens.text = "Greens: %d" % p0.greens
	p0_labels.blues.text  = "Blues:  %d" % p0.blues

	p1_labels.moves.text  = "Moves:  %d" % p1.moves
	p1_labels.hp.text     = "HP:     %d" % p1.health
	p1_labels.shield.text = "Shield: %d" % p1.shield
	p1_labels.reds.text   = "Reds:   %d" % p1.reds
	p1_labels.greens.text = "Greens: %d" % p1.greens
	p1_labels.blues.text  = "Blues:  %d" % p1.blues
	
	if current_player_index == 0:
		_set_labels_color(p0_labels, active_color)
		_set_labels_color(p1_labels, inactive_color)
	else:
		_set_labels_color(p0_labels, inactive_color)
		_set_labels_color(p1_labels, active_color)

func _set_labels_color(labels, color):
	labels.moves.modulate = color



func make2darray():
	var array =[];
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null);
	return array

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

func pix_2_grid(pixel_x,pixel_y):
	var new_x = round((pixel_x - x_start)/offset);
	var new_y = round((pixel_y - y_start)/-offset);
	return Vector2(new_x,new_y);


func is_in_grid(grid_pos):
	if grid_pos.x >= 0 && grid_pos.x < width:
		if grid_pos.y >= 0 && grid_pos.y < height:
			return true;
	return false;

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
	if state == move:
		click_input();

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
	if player.shield >= damage:
		player.shield -= damage
	else:
		var leftover = damage - player.shield
		player.shield = 0
		player.health = max(player.health - leftover, 0)


func destroy_matched():
	var was_matched = false;
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					was_matched = true;
					all_pieces[i][j].queue_free();
					all_pieces[i][j] = null;
	move_checked = true;
	if was_matched:
		get_parent().get_node("collapse_timer").start();
	else:
		swap_back();

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
	
	
	# Decrease moves
	players[current_player_index].moves -= 1

	# Switch player if out of moves
	if players[current_player_index].moves <= 0:
		current_player_index = 1 - current_player_index  # Toggle
		players[current_player_index].moves = 3
		
	update_stats();


func _on_destroy_timer_timeout():
	destroy_matched();


func _on_collapse_timer_timeout():
	collapse_columns();


func _on_refill_timer_timeout():
	refill_columns();
