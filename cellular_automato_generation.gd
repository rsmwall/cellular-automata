class_name CellularAutomataGenerator
extends Node

signal generation_done(map: Array[Array])

@export var integer_for_main_cave := 2

# probabilidade inicial da celula viva
@export var initial_percentage := 0.4

# numero minimo de celulas vizinhas necessarias para gerar uma nova celula
@export var min_propagation_count := 4

# numero maximo de celulas vizinhas necessarias para gerar uma nova celula
@export var max_propagation_count := 8

# contagem do numero de iteracoes que o gerador ira rodar
@export var iteration_count := 4

@export var integer_for_live_cell := 1
@export var integer_for_dead_cell := 0

func generate(size := Vector2(50, 50)) -> Array[Array]:
	var map := _intial_spawn(size)
	generation_done.emit(map)
	for i in iteration_count:
		map = next_generation(map)
		generation_done.emit(map)
	return map

# retorna uma matriz 2D representando as celulas em um mapa
# 1 esta vivo e 0 esta morto
func _intial_spawn(size := Vector2(50, 50)) -> Array[Array]:
	var map: Array[Array] = []
	for i in size.x:
		map.push_back([])
		for j in size.y:
			var is_cell_alive := randf() <= initial_percentage
			var cell_value: int = integer_for_live_cell if is_cell_alive else integer_for_dead_cell
			map[i].push_back(cell_value)

	return map

func next_generation(starting_map: Array[Array]) -> Array[Array]:
	var resulting_map: Array[Array] = []
	for col in starting_map.size():
		var column_array: Array = starting_map[col]
		resulting_map.push_back([])
		for row in column_array.size():
			var current_cell: int = starting_map[col][row]

			var neighbor_position_diff: Array[Vector2] = [
				Vector2(+1, 0),
				Vector2(+1, +1),
				Vector2(0, +1),
				Vector2(-1, +1),
				Vector2(-1, 0),
				Vector2(-1, -1),
				Vector2(0, -1),
				Vector2(1, -1)]

			# contagem de celulas vizinhas ativas
			var neighbor_count := 0
			for neighbor_pos in neighbor_position_diff:
				var neighbor_cell_value: int = integer_for_dead_cell
				if col + neighbor_pos.x >= 0 && col + neighbor_pos.x < starting_map.size() \
					&& row + neighbor_pos.y >= 0 && row + neighbor_pos.y < column_array.size():
					neighbor_cell_value = starting_map[col + neighbor_pos.x][row + neighbor_pos.y]

				if neighbor_cell_value == integer_for_live_cell:
					neighbor_count += 1

			var resulting_cell_value :int = integer_for_dead_cell
			if neighbor_count >= min_propagation_count && neighbor_count <= max_propagation_count:
				resulting_cell_value = integer_for_live_cell


			resulting_map[col].push_back(resulting_cell_value)

	return resulting_map

# analisa a matriz gerada e retorna um dicionario com os dados da caverna
func analyze_connectivity(map: Array[Array]) -> Dictionary:
	var width = map.size()
	var height = map[0].size()
	var visited: Array[Array] = []

	# prepara a matriz de visitados
	for x in width:
		var col = []
		col.resize(height)
		col.fill(false)
		visited.push_back(col)

	var total_floor_cells = 0
	var max_cave_size = 0

	# percorre todo o mapa
	for x in width:
		for y in height:
			# conta todas as células de chão
			if map[x][y] == integer_for_live_cell:
				total_floor_cells += 1

			# se encontrou um chão não visitado, inicia um Flood Fill
			if map[x][y] == integer_for_live_cell and not visited[x][y]:
				var current_cave_size = _flood_fill(x, y, map, visited)
				if current_cave_size > max_cave_size:
					max_cave_size = current_cave_size

	var connectivity: float = 0.0
	if total_floor_cells > 0:
		connectivity = float(max_cave_size) / float(total_floor_cells)

	return {
		"chao_total": total_floor_cells,
		"maior_caverna": max_cave_size,
		"conectividade": connectivity
	}

# algoritmo de Flood Fill iterativo (usando array como Pilha para evitar stack overflow)
func _flood_fill(start_x: int, start_y: int, map: Array[Array], visited: Array[Array]) -> int:
	var width = map.size()
	var height = map[0].size()
	var cave_size = 0
	var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]

	while not stack.is_empty():
		var tile = stack.pop_back()
		var tx = tile.x
		var ty = tile.y

		# ignora se estiver fora dos limites ou já visitado
		if tx < 0 or tx >= width or ty < 0 or ty >= height:
			continue
		if visited[tx][ty] or map[tx][ty] == integer_for_dead_cell:
			continue

		visited[tx][ty] = true
		cave_size += 1

		# adiciona os 4 vizinhos adjacentes (N, S, E, O) à pilha
		stack.push_back(Vector2i(tx + 1, ty))
		stack.push_back(Vector2i(tx - 1, ty))
		stack.push_back(Vector2i(tx, ty + 1))
		stack.push_back(Vector2i(tx, ty - 1))

	return cave_size

# retorna os dados estatísticos, pinta a caverna principal e faz a poda
func analyze_and_paint_connectivity(map: Array[Array]) -> Dictionary:
	var width = map.size()
	var height = map[0].size()
	var visited: Array[Array] = []
	
	# prepara a matriz de visitados
	for x in width:
		var col = []
		col.resize(height)
		col.fill(false)
		visited.push_back(col)
		
	var total_floor = 0
	var largest_region: Array[Vector2i] = []
	
	# encontra a maior caverna
	for x in width:
		for y in height:
			if map[x][y] == integer_for_live_cell:
				total_floor += 1
			
	# se achou chão não visitado, mapeia a região inteira
			if map[x][y] == integer_for_live_cell and not visited[x][y]:
				var current_region = _get_region(x, y, map, visited)
				if current_region.size() > largest_region.size():
					largest_region = current_region
					
	# 1. pinta a maior caverna de verde
	for tile in largest_region:
		map[tile.x][tile.y] = integer_for_main_cave
		
	var connectivity = 0.0
	if total_floor > 0:
		connectivity = float(largest_region.size()) / float(total_floor)
		
	return {
		"chao_total": total_floor,
		"maior_caverna": largest_region.size(),
		"conectividade": connectivity,
		"mapa_modificado": map
	}

# algoritmo Flood Fill iterativo que retorna os blocos da caverna (4 Direções - Von Neumann)
func _get_region(start_x: int, start_y: int, map: Array[Array], visited: Array[Array]) -> Array[Vector2i]:
	var region: Array[Vector2i] = []
	var stack: Array[Vector2i] = [Vector2i(start_x, start_y)]
	var w = map.size()
	var h = map[0].size()
	
	while not stack.is_empty():
		var tile = stack.pop_back()
		var tx = tile.x
		var ty = tile.y
		
		# ignora se sair dos limites do mapa
		if tx < 0 or tx >= w or ty < 0 or ty >= h: 
			continue
			
		# ignora se já visitou ou se é uma parede/célula morta (preta)
		if visited[tx][ty] or map[tx][ty] != integer_for_live_cell: 
			continue
			
		visited[tx][ty] = true
		region.push_back(tile)
		
		stack.push_back(Vector2i(tx + 1, ty))
		stack.push_back(Vector2i(tx - 1, ty))
		stack.push_back(Vector2i(tx, ty + 1))
		stack.push_back(Vector2i(tx, ty - 1))
		
	return region

# função para limpar o mapa
func prune_isolated_islands(map: Array[Array]) -> void:
	var width = map.size()
	var height = map[0].size()
	
	for x in width:
		for y in height:
			# se a célula ainda é vermelha
			if map[x][y] == integer_for_live_cell:
				# transforma em parede preta
				map[x][y] = integer_for_dead_cell
				
