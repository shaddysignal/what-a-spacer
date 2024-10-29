extends RefCounted

enum LogLevel {
	TRACE = 4, DEBUG = 3, INFO = 2, WARN = 1, ERROR = 0
}

var max_level = LogLevel.TRACE
var pattern = "%s %5s [%s] %s"

func error(message: String, node_path: NodePath):
	write(LogLevel.ERROR, message, node_path)

func warn(message: String, node_path: NodePath):
	write(LogLevel.WARN, message, node_path)

func info(message: String, node_path: NodePath):
	write(LogLevel.INFO, message, node_path)

func debug(message: String, node_path: NodePath):
	write(LogLevel.DEBUG, message, node_path)

func trace(message: String, node_path: NodePath):
	write(LogLevel.TRACE, message, node_path)

func write(level: LogLevel, message: String, node_path: NodePath):
	if max_level <= level:
		print(pattern % [Time.get_datetime_string_from_system(), level, node_path, message])

func shrtn(fn: Callable, node_path: NodePath) -> Callable:
	return fn.bind(node_path)