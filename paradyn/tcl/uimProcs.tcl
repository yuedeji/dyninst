# utilities for UIM tcl functions
# $Log: uimProcs.tcl,v $
# Revision 1.18  1997/06/03 15:33:31  karavan
# small cleanup to handle new button size
#
# Revision 1.17  1996/08/05 07:34:15  tamches
# update for tcl 7.5
#
# Revision 1.16  1996/05/06 16:41:47  naim
# Adding window to confirm whether the user wants to exit paradyn - naim
#
# Revision 1.15  1996/04/15  16:18:41  naim
# Changing from global to local grab - naim
#
# Revision 1.14  1996/04/05  21:04:27  naim
# Chaging the way grabs are done to try to make sure they don't fail - naim
#
# Revision 1.13  1996/02/21  22:35:58  tamches
# created mkDialogWindowTitle
# revamped showError to eliminate duplicates (when empty-string 2d
# arg is passed) while generally displaying multiple errors in the
# same window
#
# Revision 1.12  1995/12/28 21:52:17  tamches
# error dialog box now puts its information in a scrollable, resizable
# text widget instead of a non-scrollable, non-resizable message widget
#
# Revision 1.11  1995/12/21 22:17:48  naim
# Changing "Paradyn Error #" by "Paradyn Message #", since not every message
# is an error message - naim
#
# Revision 1.10  1995/11/29  00:23:12  tamches
# removed mkLogo; removed references to PdBitmapDir; added call
# to makeLogo
#

proc mkEntry {w {pack {top expand fillx}} args} {
        eval entry $w $args
        pack append [winfo parent $w] $w $pack
        return $w
}

proc mkFrame {w {pack {top expand fill}} args} {
        eval frame $w $args
        pack append [winfo parent $w] $w $pack
        return $w
}

proc mkMessage {w {text ""} {pack {top fillx}} args} {
        eval message $w -text \"$text\" $args
        pack append [winfo parent $w] $w $pack
        return $w
}

#----------------------------------------------------------------------------
#  Make a bar of buttons and pack into parent.  Embed the left button in an
#  additional sunken frame to indicaute that it is the default button, and
#  arrange for that button to be invoked as the default action for clicks 
#  and returns inthe dialog.
# **Changed order of every and other command klk**
#----------------------------------------------------------------------------
proc mkButtonBar {w every retval blist} {	
	upvar $retval retv
        set arg [lindex $blist 0]
        focus $w

        set i 1
        foreach arg [lrange $blist 0 end] {
            button $w.$i -text [lindex $arg 0]  -height 1 \
                    -command "$every; [lindex $arg 1]"
            pack append $w $w.$i {left expand padx 15 pady 4}
            set i [expr $i+1]
        }
}


#
#  Make a new dialog toplevel window
#
proc mkDialogWindow {w} {
    catch {destroy $w}
    toplevel $w -class Dialog -bd 0
    wm title $w "Dialog box"
    wm iconname $w "Dialog"
    wm geometry $w +425+300
# Under 7.5/4.1, the tkwait causes the window to "flicker"
# noticably.
#    tkwait visibility $w
    catch {grab $w}
    focus $w
    return $w
}

proc mkDialogWindowTitle {w theTitle} {
    catch {destroy $w}
    toplevel $w -class Dialog -bd 0 
    wm title $w $theTitle
    wm iconname $w $theTitle
    label $w.la -text $theTitle \
	    -foreground white -anchor c \
	    -font *-New*Century*Schoolbook-Bold-R-*-14-* \
	    -relief raised \
	    -background red \
	    -width 40
    pack $w.la -side top -fill x 
    catch {grab $w}
    focus $w
    return $w
}

proc explError {errorCode} {
    global pdError
    set w .error2$errorCode

    #lookup errorCode, get explanation
    set etext [lindex $pdError($errorCode) 3]

    mkDialogWindowTitle $w "Paradyn Error Explanation"
    $w configure -bg red
    frame $w.out 
    pack $w.out -padx 5 -pady 5

    # title
## **** don't forget to use class for this font!!!!
    label $w.out.top -text "Paradyn Message \#\ $errorCode Explanation" -fg red \
	-font "-Adobe-times-bold-r-normal--*-120*"    
    pack $w.out.top -pady 5 -padx 5

    # explanation text
    message $w.out.explain -width 300 -text $etext -relief groove
    pack $w.out.explain -pady 5 -padx 5

    # single button option
    button $w.out.b0 -text "OK" -command "destroy $w" \
	    -width 10 
    pack $w.out.b0 -pady 5
}

proc showErrorHistory {} {
    global pdErrorHistory
    set w .errorHist
    mkDialogWindow $w
    label $w.title -text "Paradyn Error History"
    frame $w.list
    listbox $w.list.hlist -relief groove 
    scrollbar $w.list.s -orient vert -command "$w.hlist yview"
    $w.hlist configure -yscrollcommand "$w.list.s set" 
    pack $w.title -side top
    pack $w.list.hlist $w.list.s -side left 
    pack $w.list -side top
    button $w.butt -text "OKAY" -command "destroy $w"
    pack $w.butt -side top
}

#
# a simple help error screen for paradyn
#  errorStr: text for custom error message
#  errorCode: error ID from paradyn error database
#
proc showError {errorCode errorStr} {
    global pdError pdErrorHistory
    global numErrorsShown
    global whichDefaultErrorsShown

    set w .paradynErrorWindow
    set windowOpened [winfo exists $w]
    if {!$windowOpened} {
       if {[array exists whichDefaultErrorsShown]} {
	  unset whichDefaultErrorsShown
       }
    }

    # If "errorStr" is empty and whichDefaultErrorsShown() says that a
    # default msg for this error code is already up, then we do nothing
    if {$errorStr == ""} {
       if {[array exists whichDefaultErrorsShown]} {
          if {[llength [array get whichDefaultErrorsShown $errorCode]]!=0} {
             return
	  }
       }
    }
    set whichDefaultErrorsShown($errorCode) true
   
    set retval [catch {set errRec $pdError($errorCode)}]

    if {$retval == 1} {
	set errorStr "No entry in error database for this error code."
	set etype serious
    } else {
	set etype [lindex $errRec 2]
	if {$errorStr == ""} {
	    # No error string was passed in to this routine, so use
            # the default one located in the database.
	    set errorStr [lindex $errRec 0]
	}
    }

    
    # If the main error window isn't already opened, then open it.
    set theText $w.out.mid.msg

    if {!$windowOpened} {
       set numErrorsShown 0
       
       mkDialogWindowTitle $w "Paradyn Error Window"
       $w configure -bg red
       frame $w.out -class "Paradyn.Error" 
       pack $w.out -padx 5 -pady 5 -fill both -expand true

       # Error screen header: bitmap, title and Error Number
       frame $w.out.top
       pack $w.out.top -padx 5 -pady 5 -fill both -expand false

       # specific error message text
       frame $w.out.mid
       pack $w.out.mid -expand yes -fill both  -padx 5

       scrollbar $w.out.mid.msgsb -orient vertical -command "$w.out.mid.msg yview" \
   	    -background lightgray -activebackground lightgray
       pack $w.out.mid.msgsb -side right -fill y -expand false

       text $theText -wrap word \
   	    -yscrollcommand "$w.out.mid.msgsb set" \
   	    -height 8 -width 50
       pack $theText -fill both -expand true

       # option buttons 
       frame $w.out.buttons 
       mkButtonBar $w.out.buttons {} retval {{CONTINUE ""} \
	    {EXIT PARADYN "destroy ."} }

       $w.out.buttons.2 configure -command "errorExit $w"
       $w.out.buttons.1 configure -command "destroy $w"
       pack $w.out.buttons -fill both -padx 5 -expand false

       $theText tag configure categoryTag -font "*-Helvetica-*-r-*-12-*"
       $theText tag configure errorPrefixTag -foreground red -font \
	       "-*-times-bold-r-normal--*-120*"
    } else {
       #puts stderr "window already up"
       #flush stderr

       # Since the window is already up, at least one error is already
       # being shown.  Hence, we want to insert a newline now to put some vertical
       # space between us and the error above us
       $theText insert end "\n"
    }

    incr numErrorsShown

    # Now insert the information for this specific error code:
    makeLogo $w.logo$numErrorsShown dont flat 0 red
    $theText window create end -padx 5 -pady 5 -window $w.logo$numErrorsShown

    $theText insert end "Paradyn message #$errorCode" errorPrefixTag
    $theText insert end "  (category: $etype) " categoryTag

    button $w.explain$numErrorsShown -text "Explain..." \
	    -command "explError $errorCode" \
	    -font "*-Helvetica-*-r-*-12-*" \
	    -relief groove
    $theText window create end -padx 5 -pady 5 -window $w.explain$numErrorsShown
    $theText insert end "\n"

    $theText insert end "$errorStr\n"
    
    # add this error to error history list
    lappend pdErrorHistory [list $errorCode $errorStr]
}

# Exit Paradyn, with or without core file per the user selection
# This is only called from an error condition.
#
proc errorExit {oldwin} {
    set w .exerror

    mkDialogWindowTitle $w "Exit Paradyn"
    label $w.l -text "Generate Core File (Y/N)?"
    frame $w.buttons
    mkButtonBar $w.buttons {} retval {{YES ""} {NO ""}}
    $w.buttons.1 configure -command "paradyn core -1; destroy ."
    $w.buttons.2 configure -command "destroy ."
    destroy $oldwin
    pack $w.l $w.buttons -side top -padx 10 -pady 10 
    focus $w
}

# Makes sure that the user wants to exit paradyn
#
proc procExit {} {
    set w .exitWindow
    mkDialogWindowTitle $w "Exit Paradyn"
    frame $w.fr -borderwidth 2
    pack $w.fr -side top
    label $w.fr.l -text "Are you sure (Y/N)?"
    pack $w.fr.l -side top -pady 10

    frame $w.fr.buttons
    mkButtonBar $w.fr.buttons {} retval {{YES ""} {NO ""}}
    $w.fr.buttons.1 configure -command "paradyn exit"
    $w.fr.buttons.2 configure -command "destroy $w"
    pack $w.fr.buttons -side top -fill both

    focus $w
}
