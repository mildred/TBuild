#!/usr/bin/env tclsh
# kate: hl Tcl/Tk;
set auto_path [linsert $::auto_path 0 [file normalize [file dirname $argv0]]]
set auto_path [linsert $::auto_path 0 [file normalize [pwd]]]

package require TBuild

TBuild::NotFile all


# #######################################################
#
#                     Parse arguments
#
# #######################################################

set tbuildfile "TBuildfile.tcl"
set targets ""

set i 0
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

TBuild::execute::run $targets

exit
