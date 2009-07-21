/*
**
** Entry point for TBuild
**
** *****
**
** Copyright (c) 2008 Mildred Ki'Lya <mildred593(at)online.fr>
**
** Permission is hereby granted, free of charge, to any person
** obtaining a copy of this software and associated documentation
** files (the "Software"), to deal in the Software without
** restriction, including without limitation the rights to use,
** copy, modify, merge, publish, distribute, sublicense, and/or sell
** copies of the Software, and to permit persons to whom the
** Software is furnished to do so, subject to the following
** conditions:
**
** The above copyright notice and this permission notice shall be
** included in all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
** OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
** NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
** HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
** WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
** FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
** OTHER DEALINGS IN THE SOFTWARE.
*/

#include <stdlib.h>
#include <stdio.h>
#include <tcl.h>

#include "script.h"
int Tcl_AppInit(Tcl_Interp *interp);
void set_args(Tcl_Interp *interp, int argc, char **argv);

#define Tcl_NewLiteralStringObj(sLiteral) \
    Tcl_NewStringObj((sLiteral), (int) (sizeof(sLiteral "") - 1))


int main(int argc, char* argv[]){
#if 1
    Tcl_Interp *interp;
    Tcl_Channel errChannel;
    int exitCode = 0;
    int res;

    Tcl_FindExecutable(argv[0]);

    interp = Tcl_CreateInterp();
    Tcl_InitMemory(interp);
    Tcl_Preserve((ClientData) interp);

    Tcl_SetVar(interp, "tcl_interactive", "0", TCL_GLOBAL_ONLY);
    set_args(interp, argc, argv);

    /*
     * Invoke application-specific initialization.
     */

    if (Tcl_AppInit(interp) != TCL_OK) {
	errChannel = Tcl_GetStdChannel(TCL_STDERR);
	if (errChannel) {
	    Tcl_WriteChars(errChannel,
		    "application-specific initialization failed: ", -1);
	    Tcl_WriteObj(errChannel, Tcl_GetObjResult(interp));
	    Tcl_WriteChars(errChannel, "\n", 1);
	}
    }
    if (Tcl_InterpDeleted(interp)) goto done;
    if (Tcl_LimitExceeded(interp)) goto done;

    res = Tcl_Eval(interp, script);
    if (res != TCL_OK) {
	errChannel = Tcl_GetStdChannel(TCL_STDERR);
	if (errChannel) {
	    Tcl_Obj *options = Tcl_GetReturnOptions(interp, res);
	    Tcl_Obj *keyPtr, *valuePtr;

	    keyPtr = Tcl_NewLiteralStringObj("-errorinfo");
	    Tcl_IncrRefCount(keyPtr);
	    Tcl_DictObjGet(NULL, options, keyPtr, &valuePtr);
	    Tcl_DecrRefCount(keyPtr);

	    if (valuePtr) {
		Tcl_WriteObj(errChannel, valuePtr);
	    }
	    Tcl_WriteChars(errChannel, "\n", 1);
	}
	exitCode = 1;
    }

done:

    /*
     * Rather than calling exit, invoke the "exit" command so that users can
     * replace "exit" with some other command to do additional cleanup on
     * exit. The Tcl_EvalObjEx call should never return.
     */

    if (!Tcl_InterpDeleted(interp)) {
	if (!Tcl_LimitExceeded(interp)) {
	    Tcl_Obj *cmd = Tcl_ObjPrintf("exit %d", exitCode);
	    Tcl_IncrRefCount(cmd);
	    Tcl_EvalObjEx(interp, cmd, TCL_EVAL_GLOBAL);
	    Tcl_DecrRefCount(cmd);
	}

	/*
	 * If Tcl_EvalObjEx returns, trying to eval [exit], something unusual
	 * is happening. Maybe interp has been deleted; maybe [exit] was
	 * redefined, maybe we've blown up because of an exceeded limit. We
	 * still want to cleanup and exit.
	 */

	if (!Tcl_InterpDeleted(interp)) {
	    Tcl_DeleteInterp(interp);
	}
    }

    /*
     * If we get here, the master interp has been deleted. Allow its
     * destruction with the last matching Tcl_Release.
     */

    Tcl_Release((ClientData) interp);
    Tcl_Exit(exitCode);
    return 0;
#endif
#if 0
    //Tcl_SetStartupScript(....);
    Tcl_Main(argc, argv, Tcl_AppInit);
    exit(0);
    return 0;
#endif
#if 0
    Tcl_Interp* i = Tcl_CreateInterp();
    if(i == NULL) return 1;
    Tcl_Preserve(i);
    /*
    if (Tcl_Init(i) == TCL_ERROR) {
	fprintf(stderr, "Tcl init: %s\n", Tcl_GetStringResult(i));
	Tcl_Release(i);
	Tcl_DeleteInterp(i);
	exit(1);
	return 1;
    }
    */
    int res = Tcl_Eval(i, script);
    if(res == TCL_ERROR) {
	fprintf(stderr, "script.tcl.h: %s\n", Tcl_GetStringResult(i));
	res = EXIT_FAILURE;
    } else {
	res = EXIT_SUCCESS;
    }
    Tcl_Release(i);
    Tcl_DeleteInterp(i);
    exit(res);
    return res;
#endif
}

int Tcl_AppInit(Tcl_Interp *interp) {
    /* Tcl_Init reads init.tcl from the Tcl script library. */
#if 0
    if (Tcl_Init(interp) == TCL_ERROR) {
	return TCL_ERROR;
    }
#endif
    return TCL_OK;
}

void set_args(Tcl_Interp *interp, int argc, char **argv) {
    Tcl_DString appName;
    Tcl_Obj *argvPtr;

    Tcl_ExternalToUtfDString(NULL, argv[0], -1, &appName);
    Tcl_SetVar(interp, "argv0", Tcl_DStringValue(&appName), TCL_GLOBAL_ONLY);
    Tcl_DStringFree(&appName);

    Tcl_SetVar2Ex(interp, "argc", NULL, Tcl_NewIntObj(argc), TCL_GLOBAL_ONLY);

    argvPtr = Tcl_NewListObj(0, NULL);
    while (argc--) {
	Tcl_DString ds;
	Tcl_ExternalToUtfDString(NULL, *argv++, -1, &ds);
	Tcl_ListObjAppendElement(NULL, argvPtr, Tcl_NewStringObj(
		Tcl_DStringValue(&ds), Tcl_DStringLength(&ds)));
	Tcl_DStringFree(&ds);
    }
    Tcl_SetVar2Ex(interp, "argv", NULL, argvPtr, TCL_GLOBAL_ONLY);
}

/*
** kate: hl C; indent-width 4; space-indent on; replace-tabs off;
** kate: tab-width 8; remove-trailing-space on; indent-mode cstyle;
*/
