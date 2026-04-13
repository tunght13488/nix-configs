{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    git-town
  ];

  programs.git.enable = true;
  programs.git.settings.alias = {
    # # View the SHA, description, and history graph of the latest 20 commits
    # l = "log --pretty=oneline -n 20 --graph";
    # # View the current working tree status using the short format
    # s = "status -s";
    # # Show the diff between the latest commit and the current state
    # d = "!"git diff-index --quiet HEAD -- || clear; git diff --patch-with-stat"";
    # # `git di $number` shows the diff between the state `$number` revisions ago and the current state
    # di = "!"d() { git diff --patch-with-stat HEAD~$1; }; git diff-index --quiet HEAD -- || clear; d"";
    # # Pull in remote changes for the current repository and all its submodules
    # p = "!"git pull; git submodule foreach git pull origin master"";
    # # Clone a repository including all submodules
    # c = "clone --recursive";
    # # Commit all changes
    # ca = "!git add -A && git commit -av";
    # # Switch to a branch, creating it if necessary
    # go = "checkout -B";
    # # Show verbose output about tags, branches or remotes
    # tags = "tag -l";
    # branches = "branch -a";
    # remotes = "remote -v";
    # # Credit an author on the latest commit
    # credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";
    # # Interactive rebase with the given number of latest commits
    # reb = "!r() { git rebase -i HEAD~$1; }; r";

    assume = "update-index --assume-unchanged";
    assumeall = "!git status -s | awk {'print $2'} | xargs git assume";
    assumed = "!git ls-files -v | grep ^h | cut -c 3-";
    unassume = "update-index --no-assume-unchanged";
    unassumeall = "!git assumed | xargs git update-index --no-assume-unchanged";
    up = "pull --rebase --autostash";

    # Branch (b)
    b = "branch";
    ba = "branch --all --verbose";
    bc = "checkout -b";
    bd = "branch --delete";
    bD = "branch --delete --force";
    bl = "branch --verbose";
    bL = "branch --all --verbose";
    bm = "branch --move";
    bM = "branch --move --force";
    br = "branch --move";
    bR = "branch --move --force";
    bs = "show-branch";
    bS = "show-branch --all";
    bv = "branch --verbose";
    bV = "branch --verbose --verbose";
    bx = "branch --delete";
    bX = "branch --delete --force";

    # Commit (c)
    c = "commit --verbose";
    ca = "commit --verbose --all";
    cm = "commit --message";
    cS = "commit -S --verbose";
    cSa = "commit -S --verbose --all";
    cSm = "commit -S --message";
    cam = "commit --all --message";
    co = "checkout";
    cO = "checkout --patch";
    cf = "commit --amend --reuse-message HEAD";
    cSf = "commit -S --amend --reuse-message HEAD";
    cF = "commit --verbose --amend";
    cSF = "commit -S --verbose --amend";
    cp = "cherry-pick --ff";
    cP = "cherry-pick --no-commit";
    cr = "revert";
    cR = "reset \"HEAD^\"";
    cs = "show";
    csS = "show --pretty=short --show-signature";
    # cl	= "git-commit-lost";
    cy = "cherry -v --abbrev";
    cY = "cherry -v";

    # Conflict (C)
    # alias gCl='git --no-pager diff --name-only --diff-filter=U'
    # alias gCa='git add $(gCl)'
    # alias gCe='git mergetool $(gCl)'
    Co = "checkout --ours --";
    # alias gCO='gCo $(gCl)'
    Ct = "checkout --theirs --";
    # alias gCT='gCt $(gCl)'

    # Data (d)
    d = "ls-files";
    dc = "ls-files --cached";
    dx = "ls-files --deleted";
    dm = "ls-files --modified";
    du = "ls-files --other --exclude-standard";
    dk = "ls-files --killed";
    di = "status --porcelain --short --ignored | sed -n \"s/^!! //p\"";

    # Fetch (f)
    f = "fetch";
    fa = "fetch --all";
    fc = "clone";
    fcr = "clone --recurse-submodules";
    fm = "pull";
    fr = "pull --rebase";

    # Flow (F)
    Fi = "flow init";
    Ff = "flow feature";
    Fb = "flow bugfix";
    Fl = "flow release";
    Fh = "flow hotfix";
    Fs = "flow support";

    Ffl = "flow feature list";
    Ffs = "flow feature start";
    Fff = "flow feature finish";
    Ffp = "flow feature publish";
    Fft = "flow feature track";
    Ffd = "flow feature diff";
    Ffr = "flow feature rebase";
    Ffc = "flow feature checkout";
    Ffm = "flow feature pull";
    Ffx = "flow feature delete";

    Fbl = "flow bugfix list";
    Fbs = "flow bugfix start";
    Fbf = "flow bugfix finish";
    Fbp = "flow bugfix publish";
    Fbt = "flow bugfix track";
    Fbd = "flow bugfix diff";
    Fbr = "flow bugfix rebase";
    Fbc = "flow bugfix checkout";
    Fbm = "flow bugfix pull";
    Fbx = "flow bugfix delete";

    Fll = "flow release list";
    Fls = "flow release start";
    Flf = "flow release finish";
    Flp = "flow release publish";
    Flt = "flow release track";
    Fld = "flow release diff";
    Flr = "flow release rebase";
    Flc = "flow release checkout";
    Flm = "flow release pull";
    Flx = "flow release delete";

    Fhl = "flow hotfix list";
    Fhs = "flow hotfix start";
    Fhf = "flow hotfix finish";
    Fhp = "flow hotfix publish";
    Fht = "flow hotfix track";
    Fhd = "flow hotfix diff";
    Fhr = "flow hotfix rebase";
    Fhc = "flow hotfix checkout";
    Fhm = "flow hotfix pull";
    Fhx = "flow hotfix delete";

    Fsl = "flow support list";
    Fss = "flow support start";
    Fsf = "flow support finish";
    Fsp = "flow support publish";
    Fst = "flow support track";
    Fsd = "flow support diff";
    Fsr = "flow support rebase";
    Fsc = "flow support checkout";
    Fsm = "flow support pull";
    Fsx = "flow support delete";

    # Grep (g)
    g = "grep";
    gi = "grep --ignore-case";
    gl = "grep --files-with-matches";
    gL = "grep --files-without-matches";
    gv = "grep --invert-match";
    gw = "grep --word-regexp";

    # Index (i)
    ia = "add";
    iA = "add --patch";
    iu = "add --update";
    id = "diff --no-ext-diff --cached";
    iD = "diff --no-ext-diff --cached --word-diff";
    ii = "update-index --assume-unchanged";
    iI = "update-index --no-assume-unchanged";
    ir = "reset";
    iR = "reset --patch";
    ix = "rm -r --cached";
    iX = "rm -rf --cached";

    # Log (l)
    # alias gl='git log --topo-order --pretty=format:"${_git_log_medium_format}"'
    # alias gls='git log --topo-order --stat --pretty=format:"${_git_log_medium_format}"'
    # alias gld='git log --topo-order --stat --patch --full-diff --pretty=format:"${_git_log_medium_format}"'
    # alias glo='git log --topo-order --pretty=format:"${_git_log_oneline_format}"'
    # alias glg='git log --topo-order --all --graph --pretty=format:"${_git_log_oneline_format}"'
    # alias glb='git log --topo-order --pretty=format:"${_git_log_brief_format}"'
    lc = "shortlog --summary --numbered";
    lS = "log --show-signature";

    ld = "log --pretty=format:\"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --date=relative";
    lds = "log --pretty=format:\"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --date=short";
    le = "log --oneline --decorate";
    lg = "log --color --graph --pretty=format:'%C(yellow)%h%Creset %C(red bold)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
    lga = "log --color --graph --pretty=format:'%C(yellow)%h%Creset %C(red bold)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";
    ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --numstat";
    lnc = "log --pretty=format:\"%h\\ %s\\ [%cn]\"";
    lol = "log --oneline --decorate --graph";
    lola = "log --oneline --decorate --graph --all";

    # Merge (m)
    m = "merge";
    mC = "merge --no-commit";
    mF = "merge --no-ff";
    ma = "merge --abort";
    mt = "mergetool";

    # Push (p)
    p = "push";
    pf = "push --force-with-lease";
    pF = "push --force";
    pa = "push --all";
    pA = "push --all && git push --tags";
    pt = "push --tags";
    pc = "push --set-upstream origin \"$(git-branch-current 2> /dev/null)\"";
    # alias gpp='git pull origin "$(git-branch-current 2> /dev/null)" && git push origin "$(git-branch-current 2> /dev/null)"'

    # Rebase (r)
    r = "rebase";
    ra = "rebase --abort";
    rc = "rebase --continue";
    ri = "rebase --interactive";
    rs = "rebase --skip";

    # Remote (R)
    R = "remote";
    Rl = "remote --verbose";
    Ra = "remote add";
    Rx = "remote rm";
    Rm = "remote rename";
    Ru = "remote update";
    Rp = "remote prune";
    Rs = "remote show";
    # alias gRb='git-hub-browse'

    # Stash (s)
    s = "stash";
    sa = "stash apply";
    sx = "stash drop";
    # alias gsX='git-stash-clear-interactive'
    sl = "stash list";
    # alias gsL='git-stash-dropped'
    sd = "stash show --patch --stat";
    sp = "stash pop";
    # alias gsr='git-stash-recover'
    ss = "stash save --include-untracked";
    sS = "stash save --patch --no-keep-index";
    sw = "stash save --include-untracked --keep-index";

    # Submodule (S)
    S = "submodule";
    Sa = "submodule add";
    Sf = "submodule foreach";
    Si = "submodule init";
    SI = "submodule update --init --recursive";
    Sl = "submodule status";
    # alias gSm='git-submodule-move'
    Ss = "submodule sync";
    Su = "submodule foreach git pull origin master";
    # alias gSx='git-submodule-remove'

    # Tag (t)
    t = "tag";
    tl = "tag -l";
    ts = "tag -s";
    tv = "verify-tag";

    # Working Copy (w)
    # alias gws='git status --ignore-submodules=${_git_status_ignore_submodules} --short'
    # alias gwS='git status --ignore-submodules=${_git_status_ignore_submodules}'
    wd = "diff --no-ext-diff";
    wD = "diff --no-ext-diff --word-diff";
    wr = "reset --soft";
    wR = "reset --hard";
    wc = "clean -n";
    wC = "clean -f";
    wx = "rm -r";
    wX = "rm -rf";

    # br          = "branch";
    # ci          = "commit";
    # cl          = "clone";
    # co          = "checkout";
    # rev         = "merge --no-ff --no-commit";
    # cp          = "cherry-pick";
    # dc          = "diff --cached";
    # df          = "diff";
    # diffr       = "!f() { git diff "$1"^.."$1"; }; f";
    # dl          = "!git ll -1";
    # dlc         = "diff --cached HEAD^";
    # done        = "!f() { git branch | grep "$1" | cut -c 3- | grep -v done | xargs -I{} git branch -m {} done-{}; }; f";
    # dr          = "!f() { git diff "$1"^.."$1"; }; f";
    # ds          = "diff --staged";
    # dt          = "difftool";
    # dtc         = "difftool --cached";
    # dump        = "cat-file -p";
    # dw          = "diff --word-diff";
    # dws         = "diff --staged --word-diff";
    # f           = "!git ls-files | grep -i";
    # fl          = "log -u";
    # ft          = "fetch";
    # gr          = "grep -Ii";
    # gra         = "!f() { A=$(pwd) && TOPLEVEL=$(git rev-parse --show-toplevel) && cd $TOPLEVEL && git grep --full-name -In $1 | xargs -I{} echo $TOPLEVEL/{} && cd $A; }; f";
    # grep        = "grep -Ii";
    # hist        = "log --color --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
    # ign         = "ls-files -o -i --exclude-standard";
    la = "!git config -l | grep alias | cut -c 7-";
    # lasttag     = "describe --tags --abbrev=0";
    # lc          = "!f() { git ll "$1"^.."$1"; }; f";
    # ls          = "ls-files";
    # lt          = "describe --tags --abbrev=0";
    ours = "!f() { git checkout --ours $@ && git add $@; }; f";
    # pull        = "pull --ff-only";
    # r           = "reset";
    # r1          = "reset HEAD^";
    # r2          = "reset HEAD^^";
    report = "log --author='Ha The Tung' --since='2 sunday ago' --until='1 sunday ago' --format='%Cgreen%ci%Creset %s%Creset' --no-merges";
    report-csv = "log --author='Ha The Tung' --since='2 sunday ago' --until='1 sunday ago' --format='\"%ci\",\"%s\"' --no-merges";
    # rh          = "reset --hard";
    # rh1         = "reset HEAD^ --hard";
    # rh2         = "reset HEAD^^ --hard";
    # sa          = "stash apply";
    # sl          = "stash list";
    snapshot = "!git stash save \"snapshot: $(date)\" && git stash apply \"stash@{0}\"";
    # ss          = "stash save";
    # st          = "status";
    # svnd        = "svn dcommit";
    # svnl        = "svn log --oneline --show-commit";
    # svnr        = "svn rebase";
    theirs = "!f() { git checkout --theirs $@ && git add $@; }; f";
    today = "log --since=midnight --author='Ha The Tung' --oneline";
    yesterday = "log --since=yesterday.midnight --author='Ha The Tung' --oneline";
    append = "town append";
    diff-parent = "town diff-parent";
    hack = "town hack";
    new-pull-request = "town new-pull-request";
    prepend = "town prepend";
    repo = "town repo";
    ship = "town ship";
    sync = "town sync";
    delete = "town delete";
    rename = "town rename";
    compress = "town compress";
    contribute = "town contribute";
    down = "town down";
    observe = "town observe";
    park = "town park";
    propose = "town propose";
    set-parent = "town set-parent";
    continue = "town continue";
    # type        = "cat-file -t";
    # undo        = "!f() { \\\n    git reset --hard $(git rev-parse --abbrev-ref HEAD)@{${1-1}}; \\\n}; f";
    # find-merge  = "!sh -c 'commit=$0 && branch=${1:-HEAD} && (git rev-list $commit..$branch --ancestry-path | cat -n; git rev-list $commit..$branch --first-parent | cat -n) | sort -k2 -s | uniq -f1 -d | sort -n | tail -1 | cut -f2'";
    # show-merge  = "!sh -c 'merge=$(git find-merge $0 $1) && [ -n \"$merge\" ] && git show $merge'";
  };
  programs.git.settings.core = {
    # excludesfile = "~/.gitignore_global";
    # attributesfile = "~/.gitattributes";
    whitespace = "fix,space-before-tab,trailing-space,cr-at-eol";
    ignorecase = "false";
    autocrlf = "input";
    editor = "nvim";
    askpass = "git-gui--askpass";
    # pager = "less -x1,5";
    # pager = "diff-so-fancy | less --tabs=4 -RFX";
  };
  programs.git.settings.apply.whitespace = "fix";
  programs.git.settings.color = {
    ui = "auto";
    branch = {
      current = "green reverse bold";
      local = "green bold";
      remote = "yellow bold";
    };
    diff = {
      meta = "11";
      frag = "magenta bold";
      old = "red bold";
      new = "green bold";
      whitespace = "red reverse";
      func = "146 bold";
      commit = "yellow bold";
    };
    status = {
      added = "green bold";
      changed = "yellow bold";
      untracked = "red bold";
    };
    "diff-highlight" = {
      oldNormal = "red bold";
      oldHighlight = "red bold 52";
      newNormal = "green bold";
      newHighlight = "green bold 22";
    };
  };
  programs.git.settings.merge = {
    log = "true";
    conflictstyle = "diff3";
    tool = "vscode";
  };
  programs.git.settings.mergetool = {
    prompt = "false";
    keepBackup = "true";
    vscode = {
      cmd = "code --wait --merge $REMOTE $LOCAL $BASE $MERGED";
    };
  };
  programs.git.settings.branch.autosetupmerge = "true";
  programs.git.settings.branch.master.remote = "origin";
  programs.git.settings.branch.master.merge = "refs/heads/master";
  programs.git.settings.branch.main.remote = "origin";
  programs.git.settings.branch.main.merge = "refs/heads/main";
  programs.git.settings.diff.algorithm = "patience";
  programs.git.settings.diff.tool = "vscode";
  programs.git.settings.diff.submodule = "log";
  programs.git.settings.difftool.prompt = "false";
  programs.git.settings.difftool.vscode.cmd = "code --wait --diff $LOCAL $REMOTE";
  programs.git.settings.github.user = "tunght13488";
  programs.git.settings.user.name = "Ha The Tung";
  programs.git.settings.user.email = "tunght13488@gmail.com";
  programs.git.settings.user.signingkey = "063C4D3F";
  programs.git.settings.help.autocorrect = "1";
  programs.git.settings.push.default = "current";
  programs.git.settings.rerere.enabled = true;
  programs.git.settings.pull.twohead = "ort";
  programs.git.settings.checkout.workers = "0";
  programs.git.settings.init.defaultBranch = "main";
  programs.git.settings.interactive = {
    # diffFilter = "diff-so-fancy --patch";
  };

  programs.git.ignores = [
    # Nix - direnv #
    # ".direnv"
    # ".envrc"
    # "default.nix"
    # "shell.nix"

    # Git #
    # #####
    ".git"

    # KDE #
    #######
    ".directory"

    # Compiled source #
    ###################
    "*.com"
    "*.class"
    "*.dll"
    "*.exe"
    "*.o"
    "*.so"

    # Packages #
    ############
    # it's better to unpack these files and commit the raw source
    # git has its own built in compression methods
    "*.7z"
    "*.dmg"
    "*.gz"
    "*.iso"
    "*.jar"
    "*.rar"
    "*.tar"
    "*.zip"
    "*.bz2"
    "*.xz"
    "*.tgz"
    "*.zst"

    # Logs and databases #
    ######################
    "*.log"
    # *.sql
    "*.sqlite"

    # OS generated files #
    ######################
    ".DS_Store*"
    "ehthumbs.db"
    "Icon?"
    "Thumbs.db"
    "._*"
    ".Spotlight-V100"
    ".Trashes"
    "Desktop.ini"

    # Other files #
    ###############
    "*.onetoc2"
    "*~"
    "~$*"
    "*#"

    # Sublime Text 2 files #
    ########################
    "*.sublime-project"
    "*.sublime-workspace"

    # SVN files #
    #############
    ".svn/"

    # PHPStorm files #
    ##################
    ".idea/"
    "atlassian-ide-plugin.xml"
    "i18nally.json"

    # Magento files #
    #################
    ".modman/"
    ".magentointel-cache/"
    ".modgit/"

    # Picasa #
    ##########
    ".picasa.ini"

    # Permission file #
    ###################
    "*.pem"

    # Capifony #
    ############
    # Capfile
    # deploy.rb

    # Vagrant #
    ###########
    ".vagrant/"

    # Laravel IDE helper
    "_ide_helper.php"
    "_ide_helper_models.php"
    ".phpstorm.meta.php"

    # CTags
    "tags"

    # Meteoric
    "meteoric.config.sh"

    # n98-magerun
    "mage.phar"

    # Magento CommerceBug
    "app/code/local/Opencommercellc/"
    "app/etc/modules/Opencommercellc_Commercebug.xml"
    "js/commercebug/"
    # Magento CommerceBug nested
    "*/app/code/local/Opencommercellc/"
    "*/app/etc/modules/Opencommercellc_Commercebug.xml"
    "*/js/commercebug/"

    # Magento QConfig
    "app/code/community/Treynolds/"
    "app/design/adminhtml/default/default/layout/treynolds/"
    "app/design/adminhtml/default/default/template/treynolds/"
    "app/etc/modules/Treynolds_Qconfig.xml"
    "js/treynolds/"
    "skin/adminhtml/base/default/treynolds/"
    "magento/app/code/community/Treynolds/"
    "magento/app/design/adminhtml/default/default/layout/treynolds/"
    "magento/app/design/adminhtml/default/default/template/treynolds/"
    "magento/app/etc/modules/Treynolds_Qconfig.xml"
    "magento/js/treynolds/"
    #magento/skin/adminhtml/base/
    "magento/skin/adminhtml/base/default/treynolds/ajax-loader.gif"

    # Adminer
    "adminer.php"

    # VS Code
    ".vscode"

    ### Vim ###
    # swap
    ".sw[a-p]"
    ".*.sw[a-p]"
    # session
    "Session.vim"
    # temporary
    ".netrwhist"
    "*~"
    # auto-generated tag files
    "tags"
    "tags.lock"
    "tags.temp"

    # PHP-CS-Fixer
    ".php_cs.cache"

    # Covers JetBrains IDEs: IntelliJ, RubyMine, PhpStorm, AppCode, PyCharm, CLion, Android Studio and WebStorm
    # Reference: https://intellij-support.jetbrains.com/hc/en-us/articles/206544839

    # User-specific stuff
    ".idea/**/workspace.xml"
    ".idea/**/tasks.xml"
    ".idea/**/usage.statistics.xml"
    ".idea/**/dictionaries"
    ".idea/**/shelf"

    # Generated files
    ".idea/**/contentModel.xml"

    # Sensitive or high-churn files
    ".idea/**/dataSources/"
    ".idea/**/dataSources.ids"
    ".idea/**/dataSources.local.xml"
    ".idea/**/sqlDataSources.xml"
    ".idea/**/dynamic.xml"
    ".idea/**/uiDesigner.xml"
    ".idea/**/dbnavigator.xml"

    # Gradle
    ".idea/**/gradle.xml"
    ".idea/**/libraries"

    # Gradle and Maven with auto-import
    # When using Gradle or Maven with auto-import, you should exclude module files,
    # since they will be recreated, and may cause churn.  Uncomment if using
    # auto-import.
    # .idea/modules.xml
    # .idea/*.iml
    # .idea/modules

    # CMake
    "cmake-build-*/"

    # Mongo Explorer plugin
    ".idea/**/mongoSettings.xml"

    # File-based project format
    "*.iws"

    # IntelliJ
    "out/"

    # mpeltonen/sbt-idea plugin
    ".idea_modules/"

    # JIRA plugin
    "atlassian-ide-plugin.xml"

    # Cursive Clojure plugin
    ".idea/replstate.xml"

    # Crashlytics plugin (for Android Studio and IntelliJ)
    "com_crashlytics_export_strings.xml"
    "crashlytics.properties"
    "crashlytics-build.properties"
    "fabric.properties"

    # Editor-based Rest Client
    ".idea/httpRequests"

    # Android studio 3.1+ serialized cache file
    ".idea/caches/build_file_checksums.ser"

    # composer
    "composer.phar"

    # vscode
    "*.code-workspace"

  ];

  programs.git.attributes = [
    "*.png binary"
    "*.jpg binary"
    "*.gif binary"
    "*.ico binary"
    "*.gz binary"
    "*.pdf binary"
    "*.gpg binary"
  ];

  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
    # settings = { };
  };

  programs.gh.enable = true;
  programs.gh.settings.pager = "cat";
}
