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

---

## 📷 Restauração da Webcam Integrada (Intel IPU6) - Galaxy Book4 Pro

A webcam integrada deste notebook (sensor OmniVision OV02C10 sob barramento MIPI) requer drivers específicos e um daemon de relay (`v4l2-relayd`) configurado sem sandboxing restritivo para funcionar em 1080p nativo e no formato de cor `NV12`.

### Passo A: Instalação dos Drivers (AUR)
Instale os drivers DKMS do kernel, a biblioteca HAL do espaço de usuário e o plugin do GStreamer.

1. **Instale os pacotes base:**
   ```bash
   yay -S v4l2loopback-dkms intel-ipu6-dkms-git intel-ipu6-camera-bin v4l2-relayd
   ```
2. **Compilação do HAL (`intel-ipu6-camera-hal-git`):**
   * Se falhar no GCC 16 devido a avisos tratados como erros (`-Werror`), acesse a pasta `~/.cache/yay/intel-ipu6-camera-hal-git`, edite o `PKGBUILD` adicionando a etapa `prepare()` para remover o `-Werror` do `CMakeLists.txt`:
     ```bash
     prepare() {
         cd $_pkgname
         sed -i 's/-Werror//g' CMakeLists.txt
     }
     ```
   * Compile com `makepkg -si`.
3. **Compilação do plugin do GStreamer (`icamerasrc-git`):**
   * Se falhar pelo mesmo motivo, acesse a pasta `~/.cache/yay/icamerasrc-git`, edite o `PKGBUILD` adicionando a etapa `prepare()` para remover `-Werror` dos fontes:
     ```bash
     prepare() {
         cd "$srcdir/$_pkgname"
         find . -type f -exec sed -i 's/-Werror//g' {} +
     }
     ```
   * Compile com `makepkg -si`.

### Passo B: Aplicação dos Backups de Configuração
Com os drivers instalados, restaure os arquivos de configuração de hardware e serviço salvos neste repositório:

```bash
# 1. Copia a configuração do módulo v4l2loopback para carregar com os parâmetros de webcam
sudo cp webcam/v4l2loopback.conf /etc/modprobe.d/v4l2loopback.conf

# 2. Copia o perfil de resolução (1080p NV12) da câmera IPU6 para o v4l2-relayd
sudo cp webcam/ipu6.conf /etc/v4l2-relayd.d/ipu6.conf

# 3. Copia a definição customizada e sem sandbox do serviço v4l2-relayd
sudo cp webcam/v4l2-relayd@.service /etc/systemd/system/v4l2-relayd@.service
```

### Passo C: Limpeza de Cache e Ativação
Limpe o cache do GStreamer para registrar o novo plugin e ative o serviço em background:

```bash
# Limpa caches de registro
rm -rf ~/.cache/gstreamer-1.0/
sudo rm -rf /root/.cache/gstreamer-1.0/

# Recarrega o systemd e ativa o serviço de transmissão automática da câmera
sudo systemctl daemon-reload
sudo systemctl reset-failed v4l2-relayd@ipu6.service
sudo systemctl enable --now v4l2-relayd@ipu6.service
```

A câmera estará pronta para ser aberta com o atalho `webcam`.
