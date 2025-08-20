#!/bin/bash
#
# Script para gerenciar dependências locais de pacotes internos Bemol.
#
# Este script lê o pubspec.yaml, identifica pacotes versionados com Git,
# e oferece uma interface interativa para clonar/remover esses pacotes
# localmente, ajustando o `dependency_overrides` e o `.gitignore`
# automaticamente.

# --- Configurações e Cores ---
set -e
PUBSPEC_FILE="pubspec.yaml"
PACKAGES_DIR="packages"
GITIGNORE_FILE=".gitignore"

# Cores para o output
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_CYAN='\033[0;36m'
C_BOLD='\033[1m'

# --- Funções de Utilidade ---

# Imprime uma mensagem de informação
info() {
    echo -e "${C_CYAN}${C_BOLD}==>${C_RESET}${C_BOLD} $1${C_RESET}"
}

# Imprime uma mensagem de sucesso
success() {
    echo -e "${C_GREEN}${C_BOLD}==>${C_RESET}${C_BOLD} $1${C_RESET}"
}

# Imprime uma mensagem de erro e sai do script
error() {
    echo -e "${C_RED}${C_BOLD}==> ERRO:${C_RESET}${C_RED} $1${C_RESET}" >&2
    exit 1
}

# Verifica se o fvm deve ser usado
get_flutter_command() {
    if [ -f ".fvmrc" ]; then
        echo "fvm flutter"
    else
        echo "flutter"
    fi
}

# --- Funções Principais ---

# Analisa o pubspec.yaml para encontrar dependências do Git
parse_git_dependencies() {
    info "Analisando $PUBSPEC_FILE por pacotes internos..."
    # Usa awk para analisar o bloco de dependências
    # Formato da saída: name|url|ref|path
    awk '
        BEGIN { in_deps=0 }
        /^dependencies:/ { in_deps=1; next }
        /^dev_dependencies:/ { in_deps=0; next }
        in_deps && /:/ {
            if ($0 ~ / git:/) {
                gsub(/:$/, "", prev_line_name);
                name=prev_line_name;
                url=""; ref=""; path="";
            } else if (name && $0 ~ /url:/) {
                url=$2;
            } else if (name && $0 ~ /ref:/) {
                ref=$2;
            } else if (name && $0 ~ /path:/) {
                path=$2;
                print name"|"url"|"ref"|"path;
                name=""; # Reseta o nome para o próximo pacote
            } else if (name && $0 !~ /^[ ]+ / && $0 ~ /:/) {
                # Se uma nova chave de pacote aparecer, imprime o anterior se tiver URL
                if (url) print name"|"url"|"ref"|"path;
                name=""; # Reseta
            }
        }
        in_deps {
            # Salva o nome do pacote (linha anterior)
            if ($0 ~ /:/ && $0 !~ / git:/ && $0 !~ / url:/ && $0 !~ / ref:/ && $0 !~ / path:/) {
                prev_line_name = $1;
            }
        }
        END {
            # Imprime o último pacote se existir
            if (name && url) print name"|"url"|"ref"|"path;
        }
    ' "$PUBSPEC_FILE"
}

# Analisa o pubspec.yaml para encontrar overrides existentes
parse_existing_overrides() {
    if grep -q "dependency_overrides:" "$PUBSPEC_FILE"; then
        # Usa awk para extrair os nomes dos pacotes sob dependency_overrides
        awk '/dependency_overrides:/,/^$/ { if ($2 == "path:") print prev; prev=$1 }' "$PUBSPEC_FILE" | sed 's/://'
    fi
}

# Renderiza o menu interativo de checkboxes
show_interactive_menu() {
    local packages_info=("$@")
    local num_packages=${#packages_info[@]}
    local selected_indices=()
    local current_index=0

    # Pre-seleciona pacotes já em override
    local existing_overrides
    read -r -a existing_overrides <<< "$(parse_existing_overrides)"
    for i in "${!packages_info[@]}"; do
        local name
        name=$(echo "${packages_info[$i]}" | cut -d'|' -f1)
        for override in "${existing_overrides[@]}"; do
            if [[ "$name" == "$override" ]]; then
                selected_indices+=($i)
                break
            fi
        done
    done

    # Função para desenhar o menu
    draw_menu() {
        clear
        echo -e "${C_BOLD}Selecione os pacotes para usar localmente:${C_RESET}"
        echo "(Use ${C_YELLOW}↑/↓${C_RESET} para navegar, ${C_YELLOW}Espaço${C_RESET} para selecionar, ${C_YELLOW}Enter${C_RESET} para confirmar)"
        echo ""

        for i in "${!packages_info[@]}"; do
            local name
            name=$(echo "${packages_info[$i]}" | cut -d'|' -f1 | sed 's/_/ /g' | awk '{for(j=1;j<=NF;j++) $j=toupper(substr($j,1,1)) substr($j,2); print}')
            
            local checked=" "
            for sel_idx in "${selected_indices[@]}"; do
                if [[ $i -eq $sel_idx ]]; then
                    checked="x"
                    break
                fi
            done

            if [[ $i -eq $current_index ]]; then
                echo -e "${C_CYAN}❯ [${checked}] ${name}${C_RESET}"
            else
                echo "  [${checked}] ${name}"
            fi
        done
    }

    # Loop de interação
    while true; do
        draw_menu
        # Leitura da tecla
        read -rsn1 key
        case "$key" in
            "") # Enter
                break
                ;;
            " ") # Espaço
                local found=false
                local new_selected=()
                for sel_idx in "${selected_indices[@]}"; do
                    if [[ $current_index -eq $sel_idx ]]; then
                        found=true
                    else
                        new_selected+=($sel_idx)
                    fi
                done
                if ! $found; then
                    new_selected+=($current_index)
                fi
                selected_indices=("${new_selected[@]}")
                ;;
            $'\x1b') # Sequência de escape (setas)
                read -rsn2 key
                case "$key" in
                    '[A') # Seta para cima
                        current_index=$(( (current_index - 1 + num_packages) % num_packages ))
                        ;;
                    '[B') # Seta para baixo
                        current_index=$(( (current_index + 1) % num_packages ))
                        ;;
                esac
                ;;
        esac
    done

    # Retorna os nomes dos pacotes selecionados
    local final_selection=()
    for sel_idx in "${selected_indices[@]}"; do
        final_selection+=("$(echo "${packages_info[$sel_idx]}" | cut -d'|' -f1)")
    done
    echo "${final_selection[@]}"
}

# Clona um repositório, com fallback para HTTP
clone_repo() {
    local name=$1
    local url=$2
    local ref=$3

    local repo_name
    repo_name=$(basename "$url")
    local target_dir="${PACKAGES_DIR}/${repo_name}"

    if [ -d "$target_dir" ]; then
        info "Repositório ${C_YELLOW}${repo_name}${C_RESET} já existe. Pulando clone."
        return
    fi

    info "Clonando ${C_YELLOW}${repo_name}${C_RESET}..."
    mkdir -p "$PACKAGES_DIR"

    # Tenta com SSH
    local ssh_url
    ssh_url=$(echo "$url" | sed 's|https://dev.azure.com/|git@ssh.dev.azure.com:v3/|' | sed 's|/_git/|/|' | sed 's/%20/ /g')
    
    if git clone --branch "$ref" "$ssh_url" "$target_dir" 2>/dev/null; then
        success "Clonado com sucesso via SSH."
    else
        info "Falha ao clonar com SSH, tentando com HTTPs..."
        if git clone --branch "$ref" "$url" "$target_dir"; then
            success "Clonado com sucesso via HTTPs."
        else
            error "Não foi possível clonar o repositório ${repo_name}."
        fi
    fi
}

# Atualiza o arquivo .gitignore
update_gitignore() {
    local repo_path=$1
    local action=$2 # "add" ou "remove"

    if [ "$action" == "add" ]; then
        if ! grep -q "^${repo_path}$" "$GITIGNORE_FILE"; then
            info "Adicionando ${C_YELLOW}${repo_path}${C_RESET} ao .gitignore"
            echo "${repo_path}" >> "$GITIGNORE_FILE"
        fi
    elif [ "$action" == "remove" ]; then
        if grep -q "^${repo_path}$" "$GITIGNORE_FILE"; then
            info "Removendo ${C_YELLOW}${repo_path}${C_RESET} do .gitignore"
            sed -i.bak "/^${repo_path//\//\\/}$/d" "$GITIGNORE_FILE" && rm "${GITIGNORE_FILE}.bak"
        fi
    fi
}

# Atualiza o pubspec.yaml com os overrides
update_pubspec() {
    local selected_packages_info=("$@")
    info "Atualizando $PUBSPEC_FILE..."

    # 1. Remove o bloco dependency_overrides existente
    local temp_pubspec
    temp_pubspec=$(mktemp)
    awk '
        BEGIN { in_overrides=0 }
        /dependency_overrides:/ { in_overrides=1; next }
        /^[a-zA-Z_]+:/ { in_overrides=0 }
        !in_overrides { print }
    ' "$PUBSPEC_FILE" > "$temp_pubspec"
    mv "$temp_pubspec" "$PUBSPEC_FILE"

    # 2. Se houver pacotes selecionados, cria e insere o novo bloco
    if [ ${#selected_packages_info[@]} -gt 0 ]; then
        local overrides_block
        overrides_block="dependency_overrides:\n"
        for package_info in "${selected_packages_info[@]}"; do
            local name url path
            IFS='|' read -r name url _ path <<< "$package_info"
            
            local repo_name
            repo_name=$(basename "$url")
            local local_path="${PACKAGES_DIR}/${repo_name}"
            # Se o pacote original tem um sub-caminho, anexa-o
            if [ -n "$path" ]; then
                local_path="${local_path}/${path}"
            fi

            overrides_block+="  ${name}:\n    path: ${local_path}\n"
        done

        # Insere o bloco antes de dev_dependencies
        awk -v block="$overrides_block" '
            /dev_dependencies:/ && !inserted {
                printf "%s\n", block;
                inserted=1;
            }
            { print }
        ' "$PUBSPEC_FILE" > "$temp_pubspec"
        mv "$temp_pubspec" "$PUBSPEC_FILE"
    fi
    success "$PUBSPEC_FILE atualizado."
}


# --- Função de Orquestração ---

main() {
    if [ ! -f "$PUBSPEC_FILE" ]; then
        error "$PUBSPEC_FILE não encontrado no diretório atual."
    fi

    # Obtém a lista de todos os pacotes git
    local all_packages_info
    readarray -t all_packages_info < <(parse_git_dependencies)

    if [ ${#all_packages_info[@]} -eq 0 ]; then
        info "Nenhum pacote interno (via Git) encontrado em 'dependencies'."
        exit 0
    fi
    
    # Mostra o menu e obtém a seleção final do usuário
    local final_selection_names
    read -r -a final_selection_names <<< "$(show_interactive_menu "${all_packages_info[@]}")"

    # Obtém a lista de overrides que existiam antes da execução
    local initial_overrides
    read -r -a initial_overrides < <(parse_existing_overrides)
    
    local final_selection_info=()
    local all_package_names=()

    # Processa todos os pacotes para decidir o que adicionar/remover
    for package_info in "${all_packages_info[@]}"; do
        local name url ref path
        IFS='|' read -r name url ref path <<< "$package_info"
        all_package_names+=("$name")

        local repo_name
        repo_name=$(basename "$url")
        local repo_path="${PACKAGES_DIR}/${repo_name}"
        
        local is_selected=false
        for sel_name in "${final_selection_names[@]}"; do
            if [[ "$name" == "$sel_name" ]]; then
                is_selected=true
                final_selection_info+=("$package_info")
                break
            fi
        done

        if $is_selected; then
            # Ação: Adicionar/Manter
            clone_repo "$name" "$url" "$ref"
            update_gitignore "$repo_path/" "add"
        else
            # Ação: Remover
            if [ -d "$repo_path" ]; then
                info "Removendo pacote local ${C_YELLOW}${repo_name}${C_RESET}..."
                rm -rf "$repo_path"
                success "Diretório ${repo_path} removido."
            fi
            update_gitignore "$repo_path/" "remove"
        fi
    done
    
    # Atualiza o pubspec com a seleção final
    update_pubspec "${final_selection_info[@]}"

    # Executa comandos flutter
    local flutter_cmd
    flutter_cmd=$(get_flutter_command)
    info "Executando comandos Flutter..."
    if $flutter_cmd clean && $flutter_cmd pub get; then
        success "Processo concluído com sucesso!"
    else
        error "Ocorreu um erro durante '$flutter_cmd clean' ou '$flutter_cmd pub get'."
    fi
}

# --- Ponto de Entrada ---
main
