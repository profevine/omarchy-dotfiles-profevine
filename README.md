# Omarchy Dotfiles - Profevine

Este repositório contém as minhas configurações personalizadas para o Omarchy (Hyprland + Omarchy shell). Ele é a "fonte da verdade" das minhas configurações, para restaurá-las em máquinas recém-formatadas e sincronizá-las entre o desktop (`ch3n`) e o notebook (`m33po`).

## 🚀 Fluxos de Trabalho

### 1. Instalação Limpa (`restore.sh`)
Use numa máquina recém-formatada, depois de instalar o Omarchy.

**O que ele faz:**
- Aplica as configurações gerais em `~/.config/`.
- Aplica os arquivos específicos da máquina, escolhidos pelo hostname (veja abaixo).
- Copia os meus plugins do Omarchy shell e reinstala os plugins de terceiros via `omarchy plugin add`.
- Restaura as preferências do Faugus Launcher.
- Restaura os scripts em `~/.local` e ativa o serviço `fix-downloads-perms`.

**Como usar:**
```bash
bash restore.sh
```

---

### 2. Atualizar uma Máquina (`sync.sh`)
Use quando quiser baixar as configurações mais recentes que você salvou no GitHub.

**O que ele faz:**
- Atualiza o sistema Omarchy (`omarchy-update`).
- Puxa as configurações do GitHub com `git reset --hard` (sobrescrevendo mudanças locais no repositório).
- Aplica os arquivos em `~/.config/` e recarrega o Hyprland.

**Como usar:**
```bash
./sync.sh
```

> **Atenção:** o `sync.sh` ainda aplica só a configuração antiga (arquivos `.conf` do Hyprland e Waybar). A config Lua, o `shell.json`, os plugins e o Faugus só são aplicados pelo `restore.sh`.

---

### 3. Salvar Modificações (`upload.sh`)
Use na máquina onde você mexeu nas configurações e quer salvá-las no GitHub.

**O que ele faz:**
- Copia as configurações ativas do sistema (`~/.config/`) para o repositório.
- Verifica se há mudanças.
- Faz o `commit` e o `push` automáticos para o GitHub.

**Como usar:**
```bash
./upload.sh
```

*Opcional: você pode passar uma mensagem de commit personalizada:*
```bash
./upload.sh "ajustei o layout da barra"
```

---

## 📂 Arquivos Sincronizados

**Gerais (iguais em todas as máquinas):**
- **Hyprland:** `hyprland.lua`, `bindings.lua`, `looknfeel.lua`, `appearance.lua`, `autostart.lua` (e os `.conf` antigos).
- **Omarchy:** menu (`omarchy-menu.jsonc` e `menu.sh`).
- **Faugus Launcher:** `config.json`, sem a chave da SteamGridDB e sem tempo de jogo e datas.
- **Scripts extras:** serviço e atalho do Nautilus para destravar permissões em Downloads.
- **Waybar (legado):** config, estilos e scripts de clima e bateria, de antes do Omarchy shell.

**Específicos de máquina** (salvos como `<nome>.<hostname>.<ext>`, por exemplo `monitors.ch3n.lua`):
- **Hyprland:** `monitors.lua`, `input.lua`, `hyprmoncfg-monitors.lua` (e os `.conf` antigos).
- **Barra:** `omarchy/shell.json` (layout e widgets da barra).
- **Waybar (legado):** `config.jsonc`.

**Plugins do Omarchy shell** (`config/omarchy/plugins/`):
- Plugins próprios, copiados inteiros:
  - `vin3.tether-usage`: mostra na barra quantos GB foram gastos na sessão atual de tethering USB. Some quando o celular não está conectado.
  - `vin3.keyboard-layout`: mostra o layout do teclado (🇧🇷 / 💀) e troca com um clique.
- Plugins de terceiros: só a URL do git fica salva, em `config/omarchy/plugins-third-party.txt`, e o `restore.sh` reinstala cada um.

## ⚠️ Avisos
- O `sync.sh` faz um `git reset --hard`. Qualquer alteração no repositório local que não tenha ido para o GitHub será **perdida**. Rode o `upload.sh` antes de rodar o `sync.sh` em outra máquina se quiser preservar mudanças.
- Este repositório fica numa pasta do Nextcloud. Se duas máquinas mexerem nele ao mesmo tempo, o Nextcloud pode trazer arquivos antigos de volta e criar cópias `(conflicted copy ...)`. Rode `git status` antes de trabalhar, e `git pull` numa máquina antes de mexer nela.

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
