# Omarchy Dotfiles - Profevine

Este repositório contém as minhas configurações personalizadas para o Omarchy (Hyprland + Omarchy shell). Ele é a "fonte da verdade" das minhas configurações, para restaurá-las em máquinas recém-formatadas e sincronizá-las entre o desktop (`ch3n`) e o notebook (`m33po`).

## 🚀 Fluxos de Trabalho

Os três scripts usam a mesma lista de arquivos, definida em `lib.sh`. Para passar a versionar um arquivo novo, adicione-o lá.

### 1. Salvar Modificações (`upload.sh`)
Use na máquina onde você mexeu nas configurações.

**O que ele faz:**
- Para se o repositório tiver mudanças soltas, por exemplo arquivos trazidos pelo Nextcloud de outra máquina.
- Faz `git pull` antes, para não desfazer o que a outra máquina enviou.
- Copia as configurações de `~/.config/` para o repositório, separando o que é geral do que é desta máquina.
- Faz `commit` e `push`.

```bash
./upload.sh
./upload.sh "ajustei o layout da barra"   # mensagem de commit opcional
```

---

### 2. Atualizar uma Máquina (`sync.sh`)
Use para trazer para esta máquina o que foi salvo na outra.

**O que ele faz:**
- Para se o repositório tiver mudanças ou commits que ainda não foram para o GitHub, em vez de apagá-los.
- Atualiza o Omarchy (`omarchy-update`).
- Puxa o GitHub e aplica as configurações seguindo as regras de máquina abaixo.
- Recarrega o Hyprland (e avisa se a config tiver erros) e reinicia o Omarchy shell.

```bash
./sync.sh
./sync.sh --no-update   # pula o omarchy-update
```

---

### 3. Instalação Limpa (`restore.sh`)
Use numa máquina recém-formatada, depois de instalar o Omarchy. Aplica tudo, como o `sync.sh`, mas sem atualizar o sistema nem mexer no git.

```bash
bash restore.sh
```

---

## 💻 Desktop e Notebook

Cada máquina é identificada pelo hostname: `ch3n` é o desktop, `m33po` é o notebook. No repositório, a versão de uma máquina é salva como `<nome>.<hostname>.<ext>`, por exemplo `config/hypr/monitors.ch3n.lua`.

**Arquivos gerais**, iguais nas duas máquinas:
- **Hyprland:** `hyprland.lua`, `bindings.lua`, `looknfeel.lua`, `appearance.lua`, `autostart.lua`.
- **Omarchy:** menu (`omarchy-menu.jsonc` e `menu.sh`).
- **Faugus Launcher:** `config.json`, sem a chave da SteamGridDB, sem tempo de jogo e datas e sem o tamanho da janela. Ao aplicar, as preferências são mescladas no arquivo local, então esses campos continuam os de cada máquina.
- **Scripts extras:** serviço e atalho do Nautilus para destravar permissões em Downloads; `webcam-overlay`, que abre a webcam numa janelinha flutuante para tutoriais e lives (`SUPER ALT W`; `SUPER ALT [` e `]` mudam o tamanho).
- **Legado:** os `.conf` antigos do Hyprland e a Waybar, de antes do Omarchy Quattro.

**Arquivos de máquina**, sempre separados por hostname:
- **`hypr/host.lua`:** atalhos, apps e ajustes que só servem para uma das máquinas. O `hyprland.lua` carrega esse arquivo depois de todos os outros. Exemplo: o atalho da webcam do notebook fica em `host.m33po.lua`.
- **Hyprland:** `monitors.lua`, `input.lua`, `hyprmoncfg-monitors.lua`.
- **Barra:** `omarchy/shell.json`, com o layout e os widgets de cada máquina.
- **Legado:** `monitors.conf`, `input.conf`, `waybar/config.jsonc`.

Uma máquina sem versão própria de um arquivo de máquina **mantém o arquivo local**; ela nunca recebe o da outra máquina. Depois do primeiro `upload.sh` nela, a versão passa a existir.

**Exceção para um arquivo geral:** se uma das máquinas precisar de uma versão própria de um arquivo geral, crie a cópia `<nome>.<hostname>.<ext>` no repositório. A partir daí ela é usada e atualizada só naquela máquina. Para um atalho ou ajuste isolado, prefira o `host.lua`.

**Temas** (`config/omarchy/themes/`):
- `horde-forever`: tema da Horda inspirado em World of Warcraft: Forever (vermelho-sangue, ouro e carvão). Aplique com `omarchy theme set horde-forever`.
- Os papéis de parede não ficam no repositório: são imagens da Blizzard e pesam ~90 MB. O tema guarda a lista em `backgrounds.txt`, e o `sync.sh`/`restore.sh` rodam o `fetch-backgrounds.sh`, que baixa da Warcraft Wiki só o que falta. Para acrescentar uma imagem, adicione uma linha na lista.

**Plugins do Omarchy shell** (`config/omarchy/plugins/`):
- Plugins próprios, copiados inteiros:
  - `vin3.tether-usage`: mostra na barra quantos GB foram gastos na sessão atual de tethering USB. Some quando o celular não está conectado.
  - `vin3.keyboard-layout`: mostra o layout do teclado (🇧🇷 / 💀) e troca com um clique.
- Plugins de terceiros: só a URL do git fica salva, em `config/omarchy/plugins-third-party.txt`. O `sync.sh` e o `restore.sh` instalam os que faltarem.
- Um plugin instalado só aparece na barra se estiver no `shell.json` daquela máquina: `omarchy plugin enable <id>`.

## ⚠️ Avisos
- **Rode o `sync.sh` antes de mexer numa máquina.** Se as duas máquinas alterarem o mesmo arquivo geral sem sincronizar, o último `upload.sh` vence. Foi assim que o atalho da webcam do notebook se perdeu uma vez.
- Este repositório fica numa pasta do Nextcloud. Se duas máquinas mexerem nele ao mesmo tempo, o Nextcloud pode trazer arquivos antigos de volta e criar cópias `(conflicted copy ...)`. Os scripts param quando isso acontece; confira com `git status` e `git diff`.

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
