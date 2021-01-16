for {set i [expr [llength [ls *.lib] ] -1] } { $i >= 0}  { incr  i -1} {
	set lib [lindex  [ls *.lib]  $i ]
	set fp [open $lib r]
	gets $fp cnt
	set lib_name [lindex [split [lindex [split $cnt (] 1] )] 0]
	set db_name [lindex [split $lib .lib] 0]
	read_lib $lib
	write_lib  $lib_name  -format  db  -output  $db_name.db
}
