# Omarchy Dotfiles - Profevine

Este repositório contém as minhas configurações personalizadas para o Omarchy (Hyprland + Waybar). Ele foi projetado para ser a "fonte da verdade" das minhas configurações, permitindo restaurá-las facilmente em máquinas recém-formatadas ou sincronizá-las entre diferentes dispositivos.

## 🚀 Fluxos de Trabalho

### 1. Restaurar ou Atualizar uma Máquina (Modo Download)
Use este script em máquinas recém-formatadas ou quando quiser baixar as configurações mais recentes que você salvou no GitHub.

**O que ele faz:**
- Atualiza o sistema Omarchy (`omarchy-update`).
- Puxa as configurações mais recentes do GitHub (sobrescrevendo mudanças locais).
- Aplica os arquivos em `~/.config/`.
- Recarrega o Hyprland.

**Como usar:**
```bash
./sync.sh
```

---

### 2. Salvar Modificações (Modo Upload)
Use este script na máquina onde você realizou modificações nas configurações (em `~/.config/`) e deseja salvá-las no GitHub para usar em outros lugares.

**O que ele faz:**
- Copia as suas configurações ativas do sistema (`~/.config/`) para a pasta do repositório.
- Verifica se há mudanças.
- Faz o `commit` e `push` automático para o GitHub.

**Como usar:**
```bash
./upload.sh
```

*Opcional: Você pode passar uma mensagem de commit personalizada:*
```bash
./upload.sh "ajustei as cores da waybar"
```

---

## 📂 Arquivos Sincronizados
Atualmente, os scripts gerenciam as seguintes configurações:
- **Hyprland:** bindings, input, looknfeel, monitors e workspaces.
- **Waybar:** config (clima, bateria, etc) e estilos CSS.
- **Scripts Extras:** Clima customizado, controle de bateria e extensões do menu Omarchy.

## ⚠️ Aviso
O script `sync.sh` realiza um `git reset --hard`. Isso significa que qualquer alteração feita nos arquivos do repositório local que não tenha sido salva no GitHub será **perdida**. Use sempre o `upload.sh` antes de rodar o `sync.sh` em outra máquina se quiser preservar mudanças.
