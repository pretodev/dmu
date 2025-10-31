# Bash completion script for dmu (Dart Multi-Repo Utility)
# 
# Installation:
#   1. Copy this file to /etc/bash_completion.d/ or /usr/local/etc/bash_completion.d/
#   2. Or source it from your ~/.bashrc:
#      source /path/to/dmu-completion.bash
#   3. Reload your shell: source ~/.bashrc

_dmu_completions() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  commands="add remove pub-get clean completions"

  # Complete commands
  if [[ ${COMP_CWORD} -eq 1 ]]; then
    COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
    return 0
  fi

  # Complete command-specific arguments
  local command="${COMP_WORDS[1]}"
  
  case "${command}" in
    add)
      case "${prev}" in
        --path)
          # Complete directory paths
          COMPREPLY=($(compgen -d -- "${cur}"))
          return 0
          ;;
        add)
          # Complete available packages
          local packages=$(dmu completions 2>/dev/null)
          COMPREPLY=($(compgen -W "${packages}" -- "${cur}"))
          return 0
          ;;
        *)
          # Complete flags
          if [[ ${cur} == -* ]]; then
            COMPREPLY=($(compgen -W "--path --help -h" -- "${cur}"))
          else
            # Complete available packages
            local packages=$(dmu completions 2>/dev/null)
            COMPREPLY=($(compgen -W "${packages}" -- "${cur}"))
          fi
          return 0
          ;;
      esac
      ;;
    
    remove)
      case "${prev}" in
        remove)
          # Complete overridden packages from pubspec.yaml
          if [[ -f "pubspec.yaml" ]]; then
            local packages=$(awk '/^dependency_overrides:/,/^[^ ]/ {if ($0 ~ /^  [a-z]/ && $0 !~ /dependency_overrides/) print $1}' pubspec.yaml | sed 's/://g')
            COMPREPLY=($(compgen -W "${packages}" -- "${cur}"))
          fi
          return 0
          ;;
        *)
          if [[ ${cur} == -* ]]; then
            COMPREPLY=($(compgen -W "--help -h" -- "${cur}"))
          fi
          return 0
          ;;
      esac
      ;;
    
    clean)
      if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "--deep -d --help -h" -- "${cur}"))
      fi
      return 0
      ;;
    
    pub-get|completions)
      if [[ ${cur} == -* ]]; then
        COMPREPLY=($(compgen -W "--help -h" -- "${cur}"))
      fi
      return 0
      ;;
  esac
}

complete -F _dmu_completions dmu
