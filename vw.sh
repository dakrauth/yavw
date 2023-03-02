#!/usr/bin/env bash
# A mashup of the old virtualenvwrapper and helper aliases.
# The basic idea is that all venv dirs are housed under 1 directory so as not to
# pollute individual repositories.
# You should set VW_HOME upstream, otherwise the default will be ~/.venvs

# set -e

export VW_HOME=${VW_HOME:=~/.venvs}
mkdir -p "${VW_HOME}"
vw__shell=${SHELL##*/}

function vw__pyversion() {
    local result
    result=$(python -V 2>&1 | cut -f2 -d" ")
    echo "${result%.*}"
}

function vw__help() {
    echo "vw -- a venv convenience wrapper"
    echo "    A mashup of the old virtualenvwrapper and helper aliases."
    echo "    Virtual environments will be created in the \$VW_HOME ($VW_HOME)"
    echo
    echo "Examples:"
    echo "---------"
    echo "   vw            # show listing of available venvs"
    echo "   vw <foo>      # activate venv foo if it exists or first create it"
    echo "   vw.x          # deactivate the current venv"
    echo "   vw.rm <foo>   # remove the foo venv"
    echo "   vw.ls         # list the venv's site-packages dir"
    echo "   vw.cd         # change dir to the current venv"
    echo "   vw.cds        # change dir to the current venv's site-packages dir"
    echo "   vw.what       # show current venv"
    echo
    echo "Shortcuts:"
    echo "----------"
    vw__aliases
}

function vw__which() {
    if [ "$VIRTUAL_ENV" ]; then
        local pyver
        pyver=$(python -V 2>&1 | cut -d" " -f 2)
        echo "VIRTUAL_ENV = $VIRTUAL_ENV (${pyver})"
    else
        echo VIRTUAL_ENV Not Set
    fi
}

function vw__where() {
    local where="$1"
    if [[ ${where} =~ "/" ]]; then
        local result
        result=$(python -c "import os,sys;print(os.path.abspath(sys.argv[1]))" "${where}")
        echo "${result}"
    else
        echo "$VW_HOME/$where"
    fi
}

function vw__show() {
    local ver=""
    for name in "$VW_HOME"/*; do
        if [[ -d "$name" && -e "$name/bin/python" ]]; then
            ver=$("$name/bin/python" -V 2>&1 | cut -d" " -f 2)
            printf "%-20s %s\n" "$(basename "$name")" "$ver"
        fi
    done
}

function vw__make() {
    local name="$1"
    local pyver
    pyver=$(python -V 2>&1 | cut -d" " -f 2)
    if [ -z "$name" ]; then
        vw__show
        return 0
    else
        local fullpath
        fullpath="$(vw__where "$name")"
        if [ "$VIRTUAL_ENV" ]; then
            echo Deactivating: "$VIRTUAL_ENV"
            deactivate > /dev/null 2>&1
        fi

        if [ -d "$fullpath" ]; then
            echo "Found $fullpath"
        else
            if [[ ${pyver} =~ "^2" ]]; then
                echo "Creating venv $fullpath with Python ${pyver} (using virtualenv)"
                virtualenv "$fullpath"
            else
                echo "Creating venv $fullpath with Python ${pyver} (using python -m venv)"
                python -m venv "$fullpath"
            fi
        fi
        echo Activating "$fullpath"

        # shellcheck source=/dev/null
        source "$fullpath/bin/activate"
    fi
}

function vw__location() {
    if [[ -z $1 ]]; then
        echo "$VIRTUAL_ENV"/lib/python"$(vw__pyversion)"/site-packages
    else
        echo "$VIRTUAL_ENV/$1"
    fi
}

function vw__cd() {
    if [ "$VIRTUAL_ENV" ]; then
        pushd "$(vw__location "$1")" || exit
    else
        echo "Virtual env not activated"
    fi
}

function vw__remove () {
    for arg in "$@"; do
        local where
        where=$(vw__where "$arg")
        if [ "$where" != "/" ]; then
            if [ "$where" = "$VIRTUAL_ENV" ]; then
                deactivate > /dev/null 2>&1
            fi
            echo Removing "$where"
            rm -rf "$where"
        fi
    done
}

function vw__list() {
    if [ "$VIRTUAL_ENV" ]; then
        local location
        location=$(vw__location "$1")
        echo "Listing $location"
        ls -Al "$location"
    else
        echo "Virtual env not activated"
    fi
}

function vw__aliases() {
    if [[ "$SHELL" =~ "zsh" ]];
    then
        alias | grep "vw\." | awk -F= '{print $1}'
    else
        alias | grep "alias vw\." | awk -F"[ =]" '{print $2}'
    fi
}

function vw__reload() {
    if [[ "$vw__shell" = "zsh" ]]; then
        echo "zsh Reloading ${(%):-%x}"
        # shellcheck source=/dev/null
        source "${(%):-%x}"
    else
        echo "bash Reloading ${BASH_SOURCE[0]}"
        # shellcheck source=/dev/null
        source "${BASH_SOURCE[0]}"
    fi
}

function vw__edit() {
    eval "$VISUAL" "$(vw__location)/$1"
}

alias vw='vw__make'
alias vw.alias='vw__aliases'
alias vw.cd='vw__cd'
alias vw.cdb='vw__cd bin'
alias vw.cds='vw__cd'
alias vw.cdsrc='vw__cd src'
alias vw.dir='vw__location'
alias vw.edit='vw__edit'
alias vw.help='vw__help'
alias vw.ls='vw__list'
alias vw.lsb='vw__list bin'
alias vw.lss='vw__list src'
alias vw.reload='vw__reload'
alias vw.rm='vw__remove'
alias vw.what='vw__which'
alias vw.which='vw__which'
alias vw.x='deactivate'
