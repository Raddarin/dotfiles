if status is-interactive
  zoxide init fish | source
    # Commands to run in interactive sessions can go here
  # Vanliga alias
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias code='code --ozone-platform=wayland'
    alias maple='./maple2025/bin/xmaple --ozone-platform=wayland'
    alias calc='python -i -c "import math"'
    alias flex='fastfetch --structure Title:Separator:OS:Host:Kernel:Uptime:Packages:Shell:Display:DE:WM:Terminal:CPU:GPU:Memory:Break:Colors'
    alias jfw='javac -cp ".:labs.jar" -d bin (find ../clock/src -name "*.java"); and java -cp ".:bin:labs.jar" ClockMain'
    alias nmtui="env NEWT_COLORS='root=,background;window=,background;shadow=,background;button=background' nmtui"

    # Programstartare i bakgrunden (fish använder >/dev/null 2>&1 istället för >/dev/null 2>&1)
    alias mm='nohup mattermost-desktop >/dev/null 2>&1 & disown; exit'
    alias viv='nohup vivaldi >/dev/null 2>&1 & disown; exit'
    alias fox='nohup firefox >/dev/null 2>&1 & disown; exit'
    alias localsend='nohup localsend >/dev/null 2>&1 & disown; exit'
    alias minecraft='nohup minecraft-launcher >/dev/null 2>&1 & disown; exit'
    alias spotify='nohup spotify-launcher >/dev/null 2>&1 & disown; exit'
    alias gem='nohup vivaldi --new-window "https://gemini.google.com/u/2/app" >/dev/null 2>&1 & disown; exit'

    # Dina egna funktioner (ersätter funktionsnamn() { ... })
    function konsys
        nohup zathura ~/Skola/konsys/formelsamling.pdf >/dev/null 2>&1 & disown
        nohup zathura ~/Skola/konsys/Kontsys.pdf >/dev/null 2>&1 & disown
        exit
    end

    function el
        nohup zathura ~/Skola/El/kursplanering_EITF90.pdf >/dev/null 2>&1 & disown
        nohup zathura ~/Skola/El/FormelsamlingKRETS2022.pdf >/dev/null 2>&1 & disown
        exit
    end

    function elMagi
        nohup zathura ~/Skola/elMagi/EF_Formelsamling2025.pdf >/dev/null 2>&1 & disown
        nohup zathura ~/Skola/elMagi/EF_Exempelsamling2025.pdf >/dev/null 2>&1 & disown
        nohup vivaldi --new-window "https://canvas.education.lu.se/courses/40848/pages/kursmaterial-och-information?module_item_id=1803145" >/dev/null 2>&1 & disown
        exit
    end

    function kassor
        nohup vivaldi --new-window "https://vault.fsektionen.se/#/login" "https://drive.google.com/drive/u/1/shared-drives" "https://docs.google.com/spreadsheets/d/12Lm7KXRW5uV3nn1LBS6xsoYgYd3sPOhM-a-fRFZ2Ft0/edit?gid=64180440#gid=64180440" "https://fsektionen.se/admin" "https://online.swedbank.se/app/ib/logga-in" "https://mail.google.com/mail/u/1/#inbox" "https://www.overleaf.com/project" "https://my.zettle.com/products?from=1&pageSize=50" "https://trello.com/b/Q0IPIotF/ledningen" "https://calendar.google.com/calendar/u/0/r" >/dev/null 2>&1 & disown
        nohup firefox --new-window "https://login.aspia.se/adfs/oauth2/authorize/?client_id=urn%3Aprd-mybusiness&redirect_uri=https%3A%2F%2Fmybusiness.aspia.se%2Fsignin-oidc&response_type=code&scope=openid%20profile&code_challenge=dH8RJ13_4Zy2zBMuQstv8_gEWX_eT2DfZpES_IoIsPE&code_challenge_method=S256&response_mode=form_post&nonce=638303750846016944.M2JlYTgyMTYtYjg5My00ZTM2LThjYWUtODg1M2NhOWQ4OTc2YTkxNWU1ZmQtOTNjYy00NDMwLTllYTMtMTQ0OWM0MmQ3MjQ2&state=CfDJ8Eg1cWlCN5RFpWUJ5SfPEJRFoIbBLZvJJ0BjZT6IiUUd_W1j1ltj6WQ72tNLRWCsqa8zJdgkKv7jEpn-pjrB84WHkPGQWVihkAwv9TBeEO8nihbrKOoc5tSmpcU1nLU6Z0X-qPQJTgmnBM91KOEE4LncrzWTRwo0Pq4qOQY-9z_vlIOWM1TEkfr-eCWWkdyy1JE__z1zdEwIkU5f72DLnezrtZP6rGTk1iYEnKAHQ63Azb-SAH2VrYxc71UVWKTSHyBUiKH1qeY4dz6S2WqrISMhXOxrX9od8ikg8jCZGPxvomI1Sn62DXcM1wDClwgXdKflwCCFlpYlNynVi8_XJvuYROd5bWTeq8MupjGJxsVxi70hGIUFbNe6FcM3sxWqWQ&x-client-SKU=ID_NETSTANDARD2_0&x-client-ver=6.10.0.0&client-request-id=0bc020fb-ea31-4055-b0f1-0080030000fc&RedirectToIdentityProvider=AD+AUTHORITY" >/dev/null 2>&1 & disown
    end

    function kass
        kassor
        exit
    end

    function styr
        kassor
        nohup vivaldi "https://trello.com/b/Q0IPIotF/ledningen" >/dev/null 2>&1 & disown
        exit
    end

    function algodat
        nohup vivaldi "https://jonasskeppstedt.net/algorithms/" >/dev/null 2>&1 & disown
        cd ~/Skola/AlgoDat/
    end

    function heroes
        cd "$HOME/gog-heroes-of-might-and-magic-3-complete-edition"; or return
        nohup wine HD_Launcher.exe >/dev/null 2>&1 & disown
        exit
    end

    # Kör ls automatiskt efter cd (ersätter din cd-wrapper utan att krocka med zoxide)
    function __auto_ls --on-variable PWD
        ls --color=auto
    end

    # Spara aktuell mapp för nya terminalfönster (ersätter PROMPT_COMMAND)
    function __save_cwd --on-event fish_prompt
        pwd > "/tmp/lastcwd-$USER"
    end
    
    function __auto_ls --on-variable PWD
        ls -l --color=auto
    end
end
starship init fish | source
