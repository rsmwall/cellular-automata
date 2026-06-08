extends Node

var generator: CellularAutomataGenerator

func _ready():
	generator = CellularAutomataGenerator.new()
	
	var test_size = Vector2(100, 100) 
	var runs_per_combination = 50
	
	# variaveis de teste
	var fill_rates = [0.40, 0.45, 0.50, 0.55]
	var iteration_cycles = [3, 5, 7]
	
	print("=========================================================")
	print("INICIANDO BENCHMARK - AUTÔMATOS CELULARES")
	print("Tamanho do Mapa: 100x100 | Execuções por Teste: ", runs_per_combination)
	print("=========================================================\n")
	
	# automatizando a mudança de parâmetros
	for fill in fill_rates:
		for iters in iteration_cycles:
			_run_test_batch(test_size, fill, iters, runs_per_combination)
			
	print("\n=========================================================")
	print("BENCHMARK CONCLUÍDO!")
	print("=========================================================")

# Função que tira as médias
func _run_test_batch(size: Vector2, fill_rate: float, iters: int, runs: int):
	var total_time_ms = 0.0
	var total_connectivity = 0.0
	
	generator.initial_percentage = fill_rate
	generator.iteration_count = iters
	
	for i in range(runs):
		# inicia o cronômetro da CPU
		var start_time = Time.get_ticks_msec()
		
		# gera o mapa silenciosamente na memória
		var final_map = generator.generate(size) 
		
		# avalia usando o Flood Fill de 4 direções
		var stats = generator.analyze_and_paint_connectivity(final_map)
		
		# realiza a poda das ilhas isoladas
		generator.prune_isolated_islands(final_map)
		
		# para o cronômetro
		var end_time = Time.get_ticks_msec()
		
		# acumula os dados
		total_time_ms += (end_time - start_time)
		total_connectivity += stats["conectividade"]
		
	# calcula as médias após as 50 execuções
	var avg_time = total_time_ms / runs
	var avg_conn = (total_connectivity / runs) * 100.0
	
	var result_text = "Preenchimento: %s | Iterações: %s  --->  Tempo Médio: %.2f ms | Conectividade Navegável: %.2f%%"
	print(result_text % [fill_rate, iters, avg_time, avg_conn])
