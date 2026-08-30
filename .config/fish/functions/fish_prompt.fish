function fish_prompt
    set -l exit_code $status

    set -l directory (string replace $HOME '~' $PWD)
    set_color 8ba4b0
    echo -n $directory
    set_color normal

    if command -q git; and git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l branch (git symbolic-ref --short HEAD 2>/dev/null; or git rev-parse --short HEAD 2>/dev/null)
        echo -n ' '
        set_color c4746e
        printf '(%s)' $branch
        set_color normal

        if test -n "$(git status --porcelain 2>/dev/null)"
            set_color c4b28a
            echo -n '*'
            set_color normal
        end
    end

    if test (count (jobs -p)) -gt 0
        echo -n ' '
        set_color c4b28a
        echo -n '⚙'
        set_color normal
    end

    echo -n ' '
    if test $exit_code -ne 0
        set_color E46876
        printf '➜ [%s]' $exit_code
    else
        set_color 8a9a7b
        echo -n '➜'
    end

    set_color normal
    echo -n '  '
end
