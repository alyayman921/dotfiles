#####################################
##==> Environment
#####################################
set -gx LS_COLORS "di=38;5;159:ln=38;5;159:ex=38;5;120:ow=38;5;212:tw=38;5;212:st=38;5;183:su=38;5;210:sg=38;5;210:or=38;5;210:mi=38;5;210:pi=38;5;183:so=38;5;183:bd=38;5;183:cd=38;5;183"
for line in (/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
    set -l parts (string split -m 1 '=' -- $line)
    if test (count $parts) -eq 2
        set -l value (string trim -c '"' -- $parts[2])
        set -gx $parts[1] $value
    end
end

#####################################
##==> Aliases
#####################################
alias cls="clear"
alias n="nvim"
alias m="micro"
alias ls="lsd"
alias tree="lsd --tree"
alias ssh="kitty +kitten ssh"

#####################################
##==> Custom Functions
#####################################
function wget
    command wget --hsts-file="$XDG_DATA_HOME/wget-hsts" $argv
end

function nvidia-settings
    mkdir -p $XDG_CONFIG_HOME/nvidia/
    command nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings" $argv
end

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

#####################################
##==> Shell Customization
#####################################
#starship init fish | source
#set fish_greeting

#####################################
##==> Fun Stuff
#####################################
#pokemon-colorscripts --no-title -s -r 1,3,6
#fastfetch
if grep -q "^ID=arch" /etc/os-release
    source ~/.fishrc
else
    source ~/.dishrc
end
#set -gx PATH $HOME/.espressif/tools/xtensa-esp-elf/esp-15.2.0_20251204/xtensa-esp-elf/bin $PATH
#set -x PATH ~/.espressif/tools/xtensa-esp32s3-elf/esp-2021r2-patch5-8.4.0/xtensa-esp32s3-elf/bin $PATH
#set -gx PATH $HOME/cuh/xtensa-esp-elf/bin/ $PATH
set -gx PATH ~/.local/bin $PATH
