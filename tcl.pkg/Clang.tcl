#!/usr/bin/env tclsh

package provide TBuild::Clang 0.1
package require TBuild

namespace eval TBuild::Clang {

  TBuild Set cflags {-Wall}

  proc obj {ofile cfile} {
    TBuild MakeSource cfile
    TBuild MakeTarget ofile
    TBuild Depends $ofile $cfile
    TBuild Depends [TBuild NotFile all] $ofile
    # TODO: make the dependance for .h files
    TBuild Make ::TBuild::Clang::_cc_c $ofile $cfile
  }

  proc _cc_c {target ofile cfile} {
    set cflags [TBuild Get $target cflags]
    eval exec gcc -o {$ofile} -c {$cfile}
  }

  proc Aliases {{prefix {TBuild Clang}}} {
    return {}
  }

  namespace export *
  namespace ensemble create

}


