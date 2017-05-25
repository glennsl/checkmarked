type t

external parseArgs : string array -> t = "minimist" [@@bs.module]

external get : t -> string -> string option = "" [@@bs.get_index] [@@bs.return {undefined_to_opt}]
external orphans : t -> string array = "_" [@@bs.get]