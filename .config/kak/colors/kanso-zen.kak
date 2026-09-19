# Static Kanso Zen for Kakoune.

evaluate-commands %sh{
    bg=rgb:090E13; bg_alt=rgb:1C1E25; bg_soft=rgb:22262D; surface=rgb:393B44
    selection=rgb:22262D; border=rgb:393B44; muted=rgb:909398; fg=rgb:C5C9C7
    fg_alt=rgb:A4A7A4; rust=rgb:b6927b
    blue=rgb:8ba4b0; cyan=rgb:8ea4a2; green=rgb:8a9a7b; green_alt=rgb:87a987
    magenta=rgb:a292a3; yellow=rgb:c4b28a; yellow_bright=rgb:E6C384; red=rgb:c4746e
    blue_bright=rgb:7FB4CA; magenta_bright=rgb:938AA9

    echo "
        set-face global value          $rust
        set-face global type           $yellow
        set-face global variable       $fg
        set-face global module         $cyan
        set-face global function       $blue
        set-face global string         $green
        set-face global keyword        $magenta_bright
        set-face global operator       $fg_alt
        set-face global attribute      $yellow_bright
        set-face global comment        $muted+i
        set-face global documentation  comment
        set-face global meta           $magenta
        set-face global builtin        $blue_bright
        set-face global identifier     $fg
        set-face global bracket        $fg_alt
        set-face global delimiter      $fg_alt

        set-face global title   $blue+b
        set-face global header  $cyan+b
        set-face global mono    $green_alt
        set-face global block   $green_alt
        set-face global link    $blue+u
        set-face global bullet  $yellow
        set-face global list    $fg

        set-face global Default            $fg,$bg
        set-face global CursorLine         default,$bg_alt
        set-face global PrimarySelection   default,$surface+g
        set-face global SecondarySelection default,$selection+g
        set-face global PrimaryCursor      $bg,$fg+fg
        set-face global SecondaryCursor    $bg,$muted+fg
        set-face global PrimaryCursorEol   $bg,$fg_alt+fg
        set-face global SecondaryCursorEol $bg,$border+fg
        set-face global LineNumbers        $muted,$bg
        set-face global LineNumberCursor   $yellow,$bg_alt+b
        set-face global LineNumbersWrapped $border,$bg
        set-face global MenuForeground     $bg,$blue
        set-face global MenuBackground     $fg,$bg_alt
        set-face global MenuInfo           $muted+i
        set-face global Information        $fg,$bg_alt
        set-face global InlineInformation  $fg,$bg_alt
        set-face global Error              $bg,$red
        set-face global StatusLine         $fg,$bg_alt
        set-face global StatusLineMode     $bg,$yellow+b
        set-face global StatusLineInfo     $cyan
        set-face global StatusLineValue    $rust
        set-face global StatusCursor       $bg,$fg
        set-face global Prompt             $yellow,$bg_alt
        set-face global MatchingChar       $yellow_bright,$bg_soft+b
        set-face global BufferPadding      $border,$bg
        set-face global Whitespace         $border+f
        set-face global WhitespaceIndent   $bg_soft+f
        set-face global WrapMarker         $border+f

        set-face global DiagnosticError        default,default,$red+c
        set-face global DiagnosticWarning      default,default,$yellow_bright+c
        set-face global DiagnosticInfo         default,default,$blue+c
        set-face global DiagnosticHint         default,default,$muted+c
        set-face global InlayDiagnosticError   $red+d
        set-face global InlayDiagnosticWarning $yellow_bright+d
        set-face global InlayDiagnosticInfo    $blue+d
        set-face global InlayDiagnosticHint    $muted+d
        set-face global LineFlagError          $red
        set-face global LineFlagWarning        $yellow_bright
        set-face global LineFlagInfo           $blue
        set-face global LineFlagHint           $muted
        set-face global InlayHint              $muted+d
        set-face global InlayCodeLens          $muted+d
        set-face global Reference              default,$surface
    "
}
