extends SceneTree
var game: Node2D
var elapsed: float = 0.0
func _initialize() -> void:
 call_deferred("_start")
func _start() -> void:
 var save: Node = root.get_node("EstadoJogo")
 save.caminho_save = "user://production_stage_codex.json"
 save.maior_fase_liberada = 1
 save.andar_escolhido = 1
 save.fase_escolhida = 1
 save.nivel = 1
 save.xp_atual = 0
 save.gold = 0
 save.inventario = []
 save.equipados = {"arma":0,"arma_secundaria":0,"cabeca":0,"peito":0,"pernas":0,"luvas":0,"acessorio":0}
 game = load("res://scenes/world/wildlands_road.tscn").instantiate()
 root.add_child(game)
 var player: Player = game.get_node("Player")
 player.velocidade = 500.0
 player.dano = 8
 player.hurtbox.configure(100)
 game._on_inventario_pressed()
 assert(game.get_node("PainelBau") != null)
func _process(delta: float) -> bool:
 if game == null: return false
 elapsed += delta
 var save: Node = root.get_node("EstadoJogo")
 if save.maior_fase_liberada >= 2:
  print("STAGE LOOP OK time=",snappedf(elapsed,0.1)," gold=",save.gold," cycle=",game.ciclo_atual)
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save.caminho_save))
  quit()
 if elapsed > 70.0:
  push_error("Fase 2 nao liberada; state="+str(game.get_node("Player/StateMachine").current.name))
  DirAccess.remove_absolute(ProjectSettings.globalize_path(save.caminho_save))
  quit(1)
 return false
