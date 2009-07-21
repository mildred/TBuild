#!/usr/bin/env tclsh

package provide TBuild::Clang 0.1
package require TBuild

namespace eval TBuild::Clang {

  TBuild Set cflags {-Wall}

  proc obj {ofile cfile {cflags {}}} {
    TBuild MakeSource cfile
    TBuild MakeTarget ofile
    TBuild Depends $ofile $cfile
    TBuild Depends all $ofile
    TBuild Set -append $ofile cflags {*}$cflags
    # TODO: make the dependance for .h files
    TBuild Make ::TBuild::Clang::_cc_c $ofile $cfile
  }

  proc exe {xfile sfiles {libs {}}} {
    TBuild MakeTarget xfile
    TBuild Depends all $xfile
    set sources [list]
    foreach ofile $sfiles {
      switch -glob -- $ofile {
	*.c {
	  set cfile $ofile
	  set ofile [string replace $ofile end-1 end .o]
	  obj $ofile $cfile
	}
      }
      TBuild MakeGlobal ofile
      TBuild Depends $xfile $ofile
      lappend sources $ofile
    }
    TBuild Set -append $xfile clibs {*}$libs
    TBuild Make ::TBuild::Clang::_cc $xfile {*}$sources
  }

  proc _cc_c {target ofile cfile} {
    set cflags [TBuild Get $target cflags]
    TBuild Exec gcc -o $ofile {*}$cflags -c $cfile
  }

  proc _cc {target ofile args} {
    set cflags [TBuild Get $target cflags]
    set clibs  [TBuild Get $target clibs]
    TBuild Exec gcc -o $ofile {*}$clibs {*}$cflags {*}$args
  }

  proc Aliases {{prefix {TBuild Clang}}} {
    return {}
  }

  namespace export *
  namespace ensemble create

}


