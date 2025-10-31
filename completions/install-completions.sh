#!/bin/bash
# Quick installer for DMU shell completions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_TYPE="${1:-auto}"

# Detect shell if auto
if [ "$SHELL_TYPE" = "auto" ]; then
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_TYPE="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_TYPE="bash"
    else
        echo "❌ Could not detect shell type. Please specify: ./install-completions.sh [zsh|bash]"
        exit 1
    fi
fi

echo "🚀 Installing DMU shell completions for $SHELL_TYPE..."

case "$SHELL_TYPE" in
    zsh)
        COMPLETIONS_DIR="${HOME}/.zsh/completions"
        mkdir -p "$COMPLETIONS_DIR"
        
        cp "${SCRIPT_DIR}/_dmu" "$COMPLETIONS_DIR/_dmu"
        echo "✅ Copied completion script to $COMPLETIONS_DIR/_dmu"
        
        ZSHRC="${HOME}/.zshrc"
        if ! grep -q "fpath=(.*\.zsh/completions" "$ZSHRC" 2>/dev/null; then
            echo "" >> "$ZSHRC"
            echo "# DMU completions" >> "$ZSHRC"
            echo "fpath=(~/.zsh/completions \$fpath)" >> "$ZSHRC"
            echo "✅ Added fpath to $ZSHRC"
        else
            echo "ℹ️  fpath already configured in $ZSHRC"
        fi
        
        echo ""
        echo "🎉 Installation complete!"
        echo ""
        echo "To activate completions, run:"
        echo "  rm -f ~/.zcompdump && exec zsh"
        ;;
    
    bash)
        COMPLETION_FILE="${HOME}/.dmu-completion.bash"
        cp "${SCRIPT_DIR}/dmu-completion.bash" "$COMPLETION_FILE"
        echo "✅ Copied completion script to $COMPLETION_FILE"
        
        BASHRC="${HOME}/.bashrc"
        if ! grep -q "source.*dmu-completion.bash" "$BASHRC" 2>/dev/null; then
            echo "" >> "$BASHRC"
            echo "# DMU completions" >> "$BASHRC"
            echo "source ~/.dmu-completion.bash" >> "$BASHRC"
            echo "✅ Added source to $BASHRC"
        else
            echo "ℹ️  Completion already sourced in $BASHRC"
        fi
        
        echo ""
        echo "🎉 Installation complete!"
        echo ""
        echo "To activate completions, run:"
        echo "  source ~/.bashrc"
        ;;
    
    *)
        echo "❌ Unknown shell type: $SHELL_TYPE"
        echo "Usage: $0 [zsh|bash|auto]"
        exit 1
        ;;
esac
