#!/usr/bin/env tclsh

package provide TBuild 0.1

namespace eval TBuild {

  variable interp {}

  variable top_target_dir [pwd]
  variable top_source_dir $top_target_dir
  variable current_dir ""

  variable search_source $top_source_dir
  variable locate_source $top_target_dir
  variable locate_target $top_target_dir

  variable targets	""
    # <target> var <varname>	variable value
    # <target> dep		list of dependancies
    # <target> inc		list of include dependancies
    # <target> make		function to call to generate target followed by
    #				the list of targets to pass as arguments
    # <target> var search	search path (list)
    # <target> var locate	locate path
    # <target> flags		flags
  variable variables	""
    # global variables

  proc UpdateVariables {} {

    variable top_target_dir
    variable top_source_dir
    variable current_dir
    variable search_source
    variable locate_source
    variable locate_target

    set search_source [file join $top_source_dir {*}$current_dir]
    set locate_source [file join $top_target_dir {*}$current_dir]
    set locate_target [file join $top_target_dir {*}$current_dir]

  }

  proc Include {args} {

    variable interp
    variable current_dir
    variable top_source_dir

    set old_current_dir $current_dir
    set current_dir [concat $current_dir $args]
    UpdateVariables
    set buildfile [file join $top_source_dir {*}$current_dir "TBuildfile.tcl"]
    interp eval $interp source $buildfile
    set current_dir $old_current_dir

  }

#   # Declare a sub directory
#   proc SubDir {varname args} {
# 
#     variable current_dir
#     variable search_source
#     variable locate_source
#     variable locate_target
# 
#     upvar $varname TOP
#     if { ! [info exists TOP] } then {
#       set TOP [pwd]
#       foreach dir $args {
# 	set TOP [file dirname $TOP]
#       }
#     }
#     set curdir $TOP
#     foreach dir $args {
#       set curdir [file join $curdir $dir]
#     }
# 
#     #puts "TOP    = $TOP"
#     #puts "SRCDIR = $curdir"
# 
#     set current_dir $curdir
#     dict set search_source $current_dir $curdir
#     dict set locate_source $current_dir $curdir
#     dict set locate_target $current_dir $curdir
# 
#   }
# 
#   # Include a sub directory
#   proc SubInc {varname args} {
# 
#     variable current_dir
# 
#     upvar $varname TOP
#     set subdir $TOP
#     foreach dir $args {
#       set subdir [file join $subdir $dir]
#     }
#     set subfile [file join $subdir "TBuildfile.tcl"]
# 
#     set mydir $current_dir
#     source $subfile
#     set current_dir $mydir
# 
#   }

  # Similar to the adding of grist in Jam
  proc MakeGlobal {args} {
    variable current_dir
    foreach varname $args {
      upvar $varname sourcevar
      set sourcevar [list $current_dir $sourcevar]
    }
  }

  proc FindSource {args} {
    variable targets
    variable search_source
    variable locate_source
    variable current_dir
    foreach arg $args {
      if {! [dict exists $targets $arg var search] } {
	dict set targets $arg var search [list $search_source]
      }
      if {! [dict exists $targets $arg var locate] } {
	dict set targets $arg var locate $locate_source
      }
    }
  }

  proc FindTarget {args} {
    variable targets
    variable current_dir
    variable locate_target
    variable current_dir
    foreach arg $args {
      # place in $locate_target
      if {! [dict exists $targets $arg var search] } {
	dict set targets $arg var search [list $locate_target]
      }
      if {! [dict exists $targets $arg var locate] } {
	dict set targets $arg var locate $locate_target
      }
    }
  }

  proc MakeSource {args} {
    foreach arg $args {
      upvar $arg var
      MakeGlobal var
      FindSource $var
    }
  }

  proc MakeTarget {args} {
    foreach arg $args {
      upvar $arg var
      MakeGlobal var
      FindTarget $var
    }
  }

  proc MakeNotFile {args} {
    variable targets
    foreach arg $args {
      upvar $arg var
      set var [list $var]
      SetFlag $var NotFile
    }
  }

  proc Source {t} {
    MakeSource t
    return $t
  }

  proc Target {t} {
    MakeTarget t
    return $t
  }

  proc NotFile {t} {
    MakeNotFile t
    return $t
  }

  proc Depends {target args} {
    variable targets
    if [dict exists $targets $target dep] {
      set dep [dict get $targets $target dep]
    } else {
      set dep ""
    }
    dict set targets $target dep [concat $dep $args]
  }

  proc DependsInc {target args} {
    variable targets
    set inc [dict get $targets $target inc]
    dict set targets $target inc [concat $inc $args]
  }

  proc Make {procname target args} {
    variable targets
    dict set targets $target make [concat $procname $args]
  }

  proc Exists {a args} {
    # ?target? var
    variable targets
    variable variables
    if [llength $args] {
      return [dict exists $targets $a var [lindex $args 0]]
    } else {
      return [dict exists $variables $a]
    }
  }

  proc Get {a args} {
    # ?target? var
    variable targets
    variable variables
    if [llength $args] {
      set b [lindex $args 0]
      if [dict exists $targets $a var $b] {
	return [dict get $targets $a var $b]
      } else {
	return [dict get $variables $b]
      }
    } else {
      return [dict get $variables $a]
    }
  }

  proc Set {args} {
    # ?-append? ?--? ?target? var val ...
    variable targets
    variable variables

    set doAppend false
    set doGlobal true
    set target ""

    set argCount [llength $args]
    for {set idx 0} {$idx < $argCount} {incr idx} {
	set flag [lindex $args $idx]
	switch -- $flag {
	    -- {
		incr idx
		break
	    }
	    -append {
		set doAppend true
	    }
	    default {
		break
	    }
	}
    }

    if {$argCount - $idx < 2} {
	return -code error "wrong # args"
    }

    set i $idx
    if {$argCount - $idx >= 3} {
      set target [lindex $args $idx]
      incr idx
      set doGlobal false
    }
    set var [lindex $args $idx]
    incr idx

    if $doAppend {
      if [catch {
	set val [Get {*}[lrange $args $i [expr $idx - 1]]]
      }] then {
	set val [lrange $args $idx end]
      } else {
	lappend val {*}[lrange $args $idx end]
      }
    } else {
      set val [lindex $args $idx]
    }

    if $doGlobal {
      return [dict set variables $var $val]
    } else {
      return [dict set targets $target var $var $val]
    }
  }

  proc Unset {a args} {
    # ?target? var
    variable targets
    variable variables
    if [llength $args] {
      return [dict unset targets $a var $b]
    } else {
      return [dict unset variables $a]
    }
  }

  proc Flags {target} {
    variable targets
    if {! [dict exists $targets $target flags] } {
      return {}
    } else {
      return [dict get $targets $target flags]
    }
  }

  proc HasFlag {target flag} {
    variable targets
    if {! [dict exists $targets $target flags] } {
      return false
    } elseif {[lsearch -exact [dict get $targets $target flags] $flag] != -1} {
      return true
    } else {
      return false
    }
  }

  proc SetFlag {target flag} {
    variable targets
    if {! [dict exists $targets $target flags] } {
      dict set targets $target flags [list flag]
    } else {
      set flags [dict get $targets $target flags]
      lappend flags $flag
      dict set targets $target flags $flags
    }
  }

  proc UnsetFlag {target flag} {
    variable targets
    if {! [dict exists $targets $target flags] } {
      dict set targets $target flags {}
    } else {
      set flags [dict get $targets $target flags]
      set new_flags ""
      for i [lsearch -exact -all -not $flags $flag] {
	lappend new_flags [lindex $flags $i]
      }
      dict set targets $target flags $new_flags
    }
  }

  proc Require {pkg} {
    package require TBuild::$pkg
    namespace export $pkg
  }

  proc FileSearch {target} {
    # TODO: add cache
    variable targets
    variable top_source_dir
    set grist  [lindex $target 0]
    set name   [lindex $target 1]
    if [dict exists $targets $target var search] {
      set search [dict get $targets $target var search]
      foreach s $search {
	set f [file join $s $name]
	if [file exists $f] {
	  return $f
	}
      }
    }
    return [file join $top_source_dir {*}$grist $name]
  }

  proc FileLocate {target} {
    # TODO: add cache
    variable targets
    variable top_target_dir
    set grist  [lindex $target 0]
    set name   [lindex $target 1]
    if [dict exists $targets $target var locate] {
      set locate [dict get $targets $target var locate]
      return [file join $locate $name]
    } else {
      return [file join $top_target_dir {*}$grist $name]
    }
  }

  proc Exec {args} {
    set code [catch {exec {*}$args} res]
    if {$code != 0} {
      return -code $code "$args\n\n$res\n"
    }
  }

  proc Aliases {{prefix {TBuild}}} {
    set res ""
    set all_functions {Include MakeGlobal FindSource FindTarget MakeSource \
      MakeTarget MakeNotFile Source Target NotFile Depends DependsInc \
      FileSearch FileLocate}
    # not exported:
    foreach func $all_functions {
      lappend res $func [list {*}$prefix $func]
    }
    return $res
  }

  namespace export Include MakeGlobal FindSource FindTarget MakeSource \
    MakeTarget MakeNotFile Source Target NotFile Depends DependsInc Make \
    Exists Get Set Unset Require FileSearch FileLocate Exec Aliases
  namespace ensemble create

}

namespace eval TBuild::execute {

  proc run {choosen_targets} {
    namespace upvar [namespace parent] targets targets
    #puts "Build targets: $choosen_targets"
    set res true
    foreach tname $choosen_targets {
      set found [find_targets $tname]
      if [dict exists $targets $tname] {
	puts "Build target $tname"
	if [catch {run_target $tname} msg] {
	  puts $msg
	  set res false
	}
      } elseif { [llength $found] == 0 } {
	puts "Can't find targets for $tname"
      }
      foreach t $found {
	puts "Build target $t"
	if [catch {run_target $t} msg] {
	  puts $msg
	  set res false
	}
      }
    }
    return $res
  }

  proc find_targets {name} {
    namespace upvar [namespace parent] targets targets
    set possible_targets ""
    set min false
    set res ""
    dict for {target _} $targets {
      if { [lindex $target 1] == $name } {
	lappend possible_targets $target
	set len [llength [lindex $target 0]]
	if { $min == false || $min > $len } {
	  set min $len
	}
      }
    }
    foreach target $possible_targets {
      set len [llength [lindex $target 0]]
      if { $len == $min } {
	lappend res $target
      }
    }
    return $res
  }

  proc run_target {target} {
    namespace upvar [namespace parent] targets targets
    set tfile [[namespace parent]::FileLocate $target]
    set mtime 0
    set rebuild true
    if [file exists $tfile] {
      set mtime [file mtime $tfile]
      set rebuild false
    }
    # Run dependancies
    foreach dep [dependancies $target] {
      run_target $dep
      set f [[namespace parent]::FileSearch $dep]
      if { ! [file exists $f] } {
	set rebuild true
      } elseif { [file mtime $f] > $mtime } {
	set rebuild true
      }
    }
    # Run target in itself
    if { $rebuild && [dict exists $targets $target make] } {
      set func  [lindex [dict get $targets $target make] 0]
      set targs [list $target]
      lappend targs {*}[lrange [dict get $targets $target make] 1 end]
      set fargs [list]
      puts [list $func $target]
      foreach targ $targs {
	set f [[namespace parent]::FileSearch $targ]
	lappend fargs $f
	#puts "[string repeat " " [string length $func]] $f"
      }
      if [catch {$func $target {*}$fargs} res] {
	puts "Error: $res"
	return -code error "Couldn't build target $target"
      }
    }
  }

  proc dependancies {target} {
    namespace upvar [namespace parent] targets targets
    set deps [list]
    if [dict exists $targets $target dep] {
      foreach dep [dict get $targets $target dep] {
	lappend deps $dep
	if [dict exists $targets $dep inc] {
	  set deps [concat $deps [dict get $targets $dep inc]]
	}
      }
    }
    return $deps
  }

}
#!/usr/bin/env tclsh
# kate: hl Tcl/Tk;

set ::auto_path [linsert $::auto_path 0 [file normalize [file dirname $argv0]]]
set ::auto_path [linsert $::auto_path 0 [file normalize [pwd]]]

#package require TBuild

TBuild::NotFile all


# #######################################################
#
#                     Parse arguments
#
# #######################################################

set tbuildfile "TBuildfile.tcl"
set targets ""

set i 1
while {$i < $argc} {
  set arg [lindex $argv $i]
  switch -regexp -- $arg {
    ^(-h|-help|--help)$ {
      set build [file tail $argv0]
      puts "NAME"
      puts ""
      puts "    $build - Build system"
      puts ""
      puts "SYNOPSYS"
      puts ""
      puts "    $build \[ -f buildfile \] \[ options \] ... \[ targets \] ..."
      puts ""
      exit
    }
    ^(-f|--file)$ {
      incr i
      if {$i < $argc} {
	set tbuildfile [file normalize [lindex $argv $i]]
	set TBuild::top_source_dir [file dirname $tbuildfile]
	TBuild::UpdateVariables
      } else {
	puts "Missing argument to -f, --file"
      }
    }
    ^(-j)$ {
      incr i
      if {$i < $argc} {
	set TBuild::execute::maxjobs [lindex $argv $i]
      } else {
	puts "Missing argument to -j"
      }
    }
    ^[a-zA-z0-9_]+= {
      regexp "^([a-zA-z0-9_])+=(.*)$" $arg varname varval
      TBuild Set $varname $varval
    }
    default {
      set targets [linsert $targets end $arg]
    }
  }
  incr i
}

if {$targets == ""} {
  set targets all
}
#puts "Building targets: $targets"



# ##########################################################
#
#                     Create Interpreter
#
# ##########################################################


set i [interp create -safe]
set TBuild::interp $i
interp alias  $i TBuild {} TBuild
interp expose $i source
interp expose $i pwd
interp hide   $i package
interp share  {} stdout $i
interp eval   $i {
  proc Alias {new args} {
    proc $new {args} "
      #[list puts $args]
      #puts \$args
      [concat $args {{*}$args}]
    "
    return $new
  }
  #proc log {args} {
  #  foreach a $args {
  #    puts $a
  #  }
  #}
  proc Aliases {args} {
    set res {}
    set i 0
    set max [llength $args]
    if { $max == 1 } {
      set args {*}$args
      set max [llength $args]
    }
    while { $i+1 < $max } {
      set new [lindex $args $i]
      incr i
      set old [lindex $args $i]
      incr i
      #puts "Alias $new $old"
      lappend res [Alias $new {*}$old]
    }
    return $res
  }
}
interp eval   $i source $tbuildfile

#puts $TBuild::targets

if [TBuild::execute::run $targets] {
  exit 0
} else {
  exit 1
}
