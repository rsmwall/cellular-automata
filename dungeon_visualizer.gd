class_name DungeonVisualizer extends Node2D

@export var map_size: Vector2i = Vector2i(1920, 1080)
@export var dungeon_generator: Node
@export var input_mode := true

var map: Array[Array]
var map_img: ImageTexture

var position_queue: Array[Vector2i] = []
var map_queue: Array = []

func _ready():
	map = dungeon_generator.generate(map_size)
	var img := Image.create_empty(map_size.x, map_size.y, false, Image.FORMAT_RGBA8)
	
	for i in map.size():
		for j in map[i].size():
			img.set_pixel(i, j, Color.BLACK)
				
	map_img = ImageTexture.create_from_image(img)
	
func _input(event):
	# quando apertar a tecla "P" (Poda)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if map.size() > 0:
			var generator = dungeon_generator as CellularAutomataGenerator
			
			# 1. chama a função de poda no mapa atual
			generator.prune_isolated_islands(map)
			
			# 2. atualiza a imagem na tela varrendo a matriz podada
			var new_img = map_img.get_image()
			
			for col in map.size():
				for row in map[col].size():
					var cell_val = map[col][row]

					if cell_val == generator.integer_for_main_cave:
						new_img.set_pixel(col, row, Color.WEB_GREEN)
					elif cell_val == generator.integer_for_live_cell:
						new_img.set_pixel(col, row, Color.CRIMSON)
					else:
						new_img.set_pixel(col, row, Color.BLACK)
			
			map_img = ImageTexture.create_from_image(new_img)
			queue_redraw()
	
	if event.is_action_pressed("ui_select"):
		if not map.is_empty():
			var stats = (dungeon_generator as CellularAutomataGenerator).analyze_and_paint_connectivity(map)
			print("Métricas do Mapa Atual: ", stats)
			map_queue.push_back(stats["mapa_modificado"])
	
	if event.is_action_pressed("ui_accept"):
		if dungeon_generator is CellularAutomataGenerator && !map_queue.is_empty():
			var map_grid = map_queue.pop_front()
			var new_img = map_img.get_image()
			
			for col in map_grid.size():
				for row in map_grid[col].size():
					var cell_val = map_grid[col][row]
					var generator = dungeon_generator as CellularAutomataGenerator

					if cell_val == generator.integer_for_main_cave:
						# caverna principal
						new_img.set_pixel(col, row, Color.WEB_GREEN)
					elif cell_val == generator.integer_for_live_cell:
						# ilhas isoladas 
						new_img.set_pixel(col, row, Color.CRIMSON)
					else:
						# parede
						new_img.set_pixel(col, row, Color.BLACK)
					
			map_img = ImageTexture.create_from_image(new_img)

			queue_redraw()

func _draw():
	if !map:
		return
		
	# pega o tamanho atual da janela/viewport
	var window_size = get_viewport_rect().size
	
	# desenha a textura preenchendo exatamente o tamanho da janela
	draw_texture_rect(map_img, Rect2(Vector2.ZERO, window_size), false)

func _on_update_timer_timeout() -> void:
	if input_mode:
		return
	
	if dungeon_generator is CellularAutomataGenerator && !map_queue.is_empty():
		var map_grid = map_queue.pop_front()
		var new_img = map_img.get_image()
		
		for col in map_grid.size():
			for row in map_grid[col].size():
				var cell_val = map_grid[col][row]
				var generator = dungeon_generator as CellularAutomataGenerator

				if cell_val == generator.integer_for_main_cave:
					# caverna principal
					new_img.set_pixel(col, row, Color.WEB_GREEN)
				elif cell_val == generator.integer_for_live_cell:
					# ilhas isoladas
					new_img.set_pixel(col, row, Color.CRIMSON)
				else:
					# parede
					new_img.set_pixel(col, row, Color.BLACK)
				
		map_img = ImageTexture.create_from_image(new_img)
	
	queue_redraw()

func _on_cellular_automato_generation_generation_done(map: Array[Array]) -> void:
	map_queue.push_back(map)
