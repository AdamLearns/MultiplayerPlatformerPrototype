extends Node

func is_dedicated_server() -> bool:
  return OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless"
