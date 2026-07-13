# Guia de Configuração da Webcam Integrada (Intel IPU6) - Galaxy Book4 Pro

Este guia documenta o passo a passo completo da solução adotada para fazer a webcam integrada Intel IPU6 (sensor OmniVision OV02C10) funcionar corretamente no Arch Linux. Use este guia se você formatar o notebook ou precisar recriar a configuração em outro sistema com a mesma arquitetura de hardware (Intel Meteor Lake / Alder Lake com IPU6).

---

## 1. Problemas Identificados no Sistema Original
1. **Falta de Drivers e HAL de Usuário:** A webcam física da Intel IPU6 necessita de uma pilha complexa de software: drivers DKMS no kernel, uma biblioteca HAL no espaço de usuário (`libcamhal`), e um plugin do GStreamer (`icamerasrc`) para ler o feed do hardware e jogá-lo no dispositivo virtual do kernel (`v4l2loopback`).
2. **Erro de Compilação com GCC 16:** Ao compilar os pacotes `-git` do AUR, o GCC 16 (mais rigoroso) tratava avisos de variáveis não utilizadas como erros fatais (`-Werror`), travando as compilações do HAL e do GStreamer.
3. **Sandbox do Systemd Bloqueando o Hardware:** O arquivo de serviço do `v4l2-relayd` padrão isolava excessivamente o sistema, impedindo que o daemon acessasse o dispositivo `/dev/ipu-psys0` necessário para processamento gráfico da IPU6.
4. **Negociação de Formato de Cor (NV12 vs YUY2):** O sensor físico da webcam só cospe dados no formato `NV12`. O serviço padrão tentava forçar a câmera a abrir em `YUY2`, o que gerava tela preta e impedia a câmera de ligar (sem acender a luz do LED).

---

## 2. Passo a Passo para Instalação e Configuração

### Passo 2.1: Instalação dos Pacotes (AUR)
Você precisa dos drivers de kernel e da biblioteca HAL instalados. Se a compilação falhar por causa de erros do GCC 16 com `-Werror`, os `PKGBUILD`s precisam ser ajustados.

1. **Instale os pacotes base de drivers e ferramentas:**
   ```bash
   yay -S v4l2loopback-dkms intel-ipu6-dkms-git intel-ipu6-camera-bin v4l2-relayd
   ```

2. **Compilação do HAL (`intel-ipu6-camera-hal-git`):**
   * Caso a compilação falhe, acesse a pasta de cache do yay:
     ```bash
     cd ~/.cache/yay/intel-ipu6-camera-hal-git
     ```
   * Modifique o arquivo `PKGBUILD` adicionando a etapa `prepare()` para remover o `-Werror` do `CMakeLists.txt`:
     ```bash
     prepare() {
         cd $_pkgname
         sed -i 's/-Werror//g' CMakeLists.txt
     }
     ```
   * Compile e instale localmente:
     ```bash
     makepkg -si
     ```

3. **Compilação do plugin do GStreamer (`icamerasrc-git`):**
   * Caso a compilação falhe, acesse a pasta de cache do yay:
     ```bash
     cd ~/.cache/yay/icamerasrc-git
     ```
   * Modifique o arquivo `PKGBUILD` adicionando a etapa `prepare()` para remover o `-Werror` das configurações do autotools:
     ```bash
     prepare() {
         cd "$srcdir/$_pkgname"
         find . -type f -exec sed -i 's/-Werror//g' {} +
     }
     ```
   * Compile e instale localmente:
     ```bash
     makepkg -si
     ```

4. **Limpeza do Cache do GStreamer:**
   Para garantir que o GStreamer detecte o novo plugin `icamerasrc`, limpe o cache de registro:
   ```bash
   rm -rf ~/.cache/gstreamer-1.0/
   sudo rm -rf /root/.cache/gstreamer-1.0/
   ```
   Valide se o plugin está ativo executando:
   ```bash
   gst-inspect-1.0 icamerasrc
   ```

---

### Passo 2.2: Persistência do Driver de Loopback (`v4l2loopback`)
Para que o dispositivo de vídeo virtual (`/dev/video0`) seja criado automaticamente no boot com a capacidade de transmissão correta (exclusiva para captura):

Crie o arquivo `/etc/modprobe.d/v4l2loopback.conf` com a seguinte linha:
```text
options v4l2loopback exclusive_caps=1 card_label="Webcam Virtual (IPU6)"
```

---

### Passo 2.3: Configuração do Daemon de Transmissão (`v4l2-relayd`)
O daemon lerá a câmera física via GStreamer e enviará a imagem para o `/dev/video0` sob demanda (ligando a câmera apenas quando um aplicativo tentar ler).

1. **Crie a configuração de perfil da câmera** em `/etc/v4l2-relayd.d/ipu6.conf`:
   ```ini
   VIDEOSRC="icamerasrc"
   FORMAT=NV12
   WIDTH=1920
   HEIGHT=1080
   FRAMERATE=30/1
   CARD_LABEL="Webcam Virtual (IPU6)"
   ```
   *(Nota: A resolução de 1920x1080 em formato NV12 é a resolução nativa da webcam FHD do Galaxy Book4 Pro, garantindo alta qualidade sem zoom ou cortes de imagem).*

2. **Crie o arquivo de serviço customizado do systemd** em `/etc/systemd/system/v4l2-relayd@.service` para desativar a sandbox restritiva e chamar o executável diretamente:
   ```ini
   [Unit]
   Description=v4l2-relay daemon service for %i
   PartOf=v4l2-relayd.service
   After=modprobe@v4l2loopback.service systemd-logind.service

   [Service]
   Type=simple
   EnvironmentFile=/etc/default/v4l2-relayd
   EnvironmentFile=-/etc/v4l2-relayd.d/%i.conf
   ExecStart=/usr/bin/v4l2-relayd -i ${VIDEOSRC} -o "appsrc name=appsrc ! video/x-raw,format=${FORMAT},width=${WIDTH},height=${HEIGHT},framerate=${FRAMERATE} ! videoconvert ! v4l2sink name=v4l2sink device=/dev/video0"
   Restart=always

   [Install]
   WantedBy=multi-user.target
   ```

---

### Passo 2.4: Ativação dos Serviços
Recarregue o systemd, limpe falhas antigas e inicie o serviço da webcam:
```bash
sudo systemctl daemon-reload
sudo systemctl reset-failed v4l2-relayd@ipu6.service
sudo systemctl enable --now v4l2-relayd@ipu6.service
```

---

## 3. Comandos de Validação e Testes
* **Verificar se o serviço está ativo:**
  ```bash
  systemctl status v4l2-relayd@ipu6.service
  ```
* **Testar a câmera física diretamente via GStreamer (bypass do daemon):**
  ```bash
  sudo gst-launch-1.0 -v icamerasrc ! "video/x-raw,format=NV12,width=1920,height=1080,framerate=30/1" ! videoconvert ! v4l2sink device=/dev/video0
  ```
* **Testar abertura da webcam via MPV (atalho local):**
  ```bash
  webcam
  ```
