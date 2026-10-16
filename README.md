# Keynest

**Encontre seu foco. / Find your focus.**

![Keynest](Resources/Keynest-preview.png)

Sons de teclado, ambientes sonoros e Pomodoro em um app nativo para macOS, feito com SwiftUI e disponível em português e inglês.

**[Baixar para macOS](https://github.com/luiizHenCode/keynest/releases/latest)** · [Versões](https://github.com/luiizHenCode/keynest/releases) · [Reportar um problema](https://github.com/luiizHenCode/keynest/issues)

## Requisitos

- macOS 14 Sonoma ou superior.
- Apple Silicon: M1 ou posterior. O instalador atual não inclui uma versão para Intel.

## Recursos

- **Teclado:** gravações reais de Cherry MX Black, Brown e Blue, com prévia e controle de volume.
- **Ambientes:** Chuva, Oceano, Floresta e Lo-fi, incluídos no app para reprodução offline.
- **Pomodoro:** foco e intervalo configuráveis, ciclos definidos ou ilimitados, transições manuais ou automáticas, sons de aviso e notificações opcionais.
- **Timer live:** painel flutuante arrastável, com opção de fixar no topo, ou contador na barra de menus.
- **Controles independentes:** ative ou pause os cliques e o ambiente separadamente.
- **Idiomas:** Sistema, Português e English, com troca sem reiniciar.

## Instalar e usar

1. Baixe o DMG em [Releases](https://github.com/luiizHenCode/keynest/releases/latest).
2. Abra o arquivo e arraste **Keynest** para **Aplicativos**.
3. Abra o Keynest e escolha o som e o volume desejados.
4. Para ouvir cliques em outros apps, autorize **Keynest** em **Ajustes do Sistema → Privacidade e Segurança → Monitoramento de Entrada**. Se solicitado, encerre e reabra o app.

O instalador oficial é assinado e notarizado pela Apple. As notificações do Pomodoro têm uma autorização separada; os ambientes e o campo de teste não precisam de Monitoramento de Entrada.

Em **Pomodoro → Ajustar sessão**, escolha os tempos e a quantidade de ciclos. Um ciclo inclui foco e intervalo, inclusive o último. Você pode pausar, retomar ou pular o intervalo.

Fechar a janela mantém o app funcionando na barra de menus. Para parar o áudio e sair, escolha **Encerrar Keynest** nesse menu.

### Privacidade e observações

- Os áudios são reproduzidos localmente, sem streaming.
- O monitoramento detecta toques sem extrair ou armazenar os caracteres digitados em outros apps. O campo de teste mantém apenas seu próprio texto temporariamente em memória, sem salvá-lo.
- Campos de senha e apps com Secure Input podem bloquear os sons globais do teclado.
- Dispositivos Bluetooth podem acrescentar latência.
- As preferências do Pomodoro são salvas, mas uma sessão ativa não é retomada depois de encerrar o app.
- O tempo em repouso do Mac conta para o Pomodoro; os avisos dependem do estado do sistema e das configurações de notificações e Foco.

## Baixar o código e modificar

Requer macOS, Xcode com as ferramentas de linha de comando e Swift 6 ou superior.

Faça um fork para manter sua própria versão ou clone o repositório:

```sh
git clone https://github.com/luiizHenCode/keynest.git
cd keynest
swift test
sh scripts/build-app.sh
open build/Keynest.app
```

Abra `Package.swift` no Xcode para editar o projeto. Depois de modificar o código, execute novamente os testes e o script de build. Builds locais usam assinatura ad-hoc e podem exigir que a permissão de Monitoramento de Entrada seja concedida novamente.

### Onde modificar

| Área | Arquivos |
| --- | --- |
| Janela de ajustes e controles | `Sources/MacTap/ContentView.swift`, `SettingsComponents.swift` |
| Sons do teclado | `Sources/MacTap/ClickSound.swift`, `KeyboardAudio.swift`, `KeyboardMonitor.swift` |
| Ambientes sonoros | `Sources/MacTap/AmbientSound.swift`, `AmbientAudio.swift` |
| Pomodoro | `Sources/MacTap/PomodoroSession.swift`, `PomodoroModel.swift`, `PomodoroView.swift` |
| Painel live e barra de menus | `Sources/MacTap/PomodoroLivePanel.swift`, `StatusBarController.swift` |
| Traduções | `Sources/MacTap/Resources/Localization/` |
| Testes | `Tests/MacTapTests/` |

Os arquivos Swift indicados na tabela ficam em `Sources/MacTap/`. O pacote e o executável internos usam o nome `MacTap`.

Para gerar um DMG local:

```sh
sh scripts/build-dmg.sh
```

## English

Keynest combines keyboard sounds, offline ambience and a Pomodoro timer in a native macOS app. Requires **macOS 14+ and Apple Silicon**.

[Download the latest release](https://github.com/luiizHenCode/keynest/releases/latest), open the DMG and drag Keynest to Applications. For keyboard sounds in other apps, allow Keynest in **System Settings → Privacy & Security → Input Monitoring**. Pomodoro notifications require a separate permission.

Choose **English** in the app's language settings or menu bar. Closing the settings window keeps the app running; use **Quit Keynest** to exit.

To modify Keynest, fork or clone this repository, open `Package.swift` in Xcode, run `swift test`, then `sh scripts/build-app.sh`. Local builds use ad-hoc signing. Original code is MIT licensed; bundled audio retains the licenses below.

## Licença e créditos

O código original do Keynest está disponível sob a [licença MIT](LICENSE), permitindo uso, modificação e redistribuição conforme suas condições.

Os áudios de terceiros mantêm suas próprias licenças e atribuições:

- [Gravações de teclado](THIRD_PARTY_NOTICES.md) — MIT.
- [Chuva](AMBIENCE_NOTICES.md) — CC BY 4.0.
- [Oceano e floresta](NATURE_NOTICES.md) — CC BY 4.0 e CC0.
- [Lo-fi](LOFI_NOTICES.md) — CC0.

Ao reutilizar os áudios, preserve os créditos e siga a licença de cada gravação.
