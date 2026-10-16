# Keynest

**Encontre seu foco. / Find your focus.**

![Keynest](Resources/Keynest-preview.png)

Keyboard sounds, offline ambience and a Pomodoro timer for macOS. Built with SwiftUI, available in Portuguese and English.

**[Download for macOS — Apple Silicon](https://github.com/luiizHenCode/keynest/releases/latest)** · **[Releases](https://github.com/luiizHenCode/keynest/releases)**

Requires macOS 14 or later. Open the DMG and drag Keynest to Applications. The official release is Developer ID signed and notarized by Apple. Global keyboard sounds require permission in **System Settings → Privacy & Security → Input Monitoring**. Pomodoro notifications use a separate notification permission.

Nome de apresentação e identidade visual: Keynest. O módulo Swift (`MacTap`), o executável interno e o bundle identifier (`com.l4apps.mactap`) permanecem estáveis para preservar compatibilidade e preferências. O nome é uma proposta de identidade; não foi feita pesquisa de marcas registradas.

## Instalar pelo DMG

O instalador gerado é `build/Keynest-1.0.0-arm64.dmg` (Apple Silicon, macOS 14+). Abra-o e arraste **Keynest** para **Aplicativos**. Encerre a cópia antiga antes de abrir `/Applications/Keynest.app`. Conceda novamente o Monitoramento de Entrada e, se usar, notificações à cópia instalada: a mudança de assinatura ad-hoc para Developer ID pode exigir nova autorização.

O instalador oficial usa assinatura Developer ID Application, Hardened Runtime e timestamp da Apple. A assinatura digital de um instalador identifica publicamente o titular e a equipe do certificado; ela não contém a chave privada. Certificados privados, senhas e credenciais de notarização não fazem parte deste repositório.

**Keynest 1.0.0: assinado e notarizado pela Apple.** Status **Accepted**. Os tickets foram anexados ao DMG e à cópia local do app; `stapler validate` e `spctl` validaram ambos com `source=Notarized Developer ID`. O SHA-256 do DMG foi recalculado após anexar o ticket. Essa aprovação vale para este binário: novas versões precisam ser assinadas e notarizadas novamente.

```sh
sh scripts/build-dmg.sh
```

O comando acima usa assinatura ad-hoc por padrão, adequada apenas para desenvolvimento local. Para distribuir, passe sua própria identidade Developer ID Application e o nome de um perfil do `notarytool` configurado localmente no Chaveiro. Estes argumentos são exemplos, não credenciais reais:

```sh
sh scripts/build-dmg.sh 'Developer ID Application: YOUR NAME (YOURTEAMID)' 'YOUR_LOCAL_NOTARY_PROFILE'
```

Substitua o segundo argumento pelo perfil existente; não envie senhas pelo chat nem as coloque no repositório. A submissão envia o instalador aos servidores de notarização da Apple. O script aguarda o resultado e valida o ticket/Gatekeeper. O checksum SHA-256 do DMG é salvo ao lado dele.

### Privacidade do repositório e dos releases

- O repositório não deve conter credenciais Apple/GitHub, e-mails pessoais, certificados privados, perfis de autenticação ou caminhos da máquina do desenvolvedor. O `.gitignore` exclui builds, configurações locais e materiais de assinatura.
- A identidade de assinatura e o perfil de notarização são argumentos locais dos scripts, não valores fixados no projeto.
- Builds de distribuição omitem informações de depuração e removem símbolos de debug antes de assinar. O executável resultante deve ser auditado para confirmar a ausência de caminhos locais antes da publicação. `scripts/sanitize-brand.py` remove metadados dos gráficos gerados sem recompactar os pixels.
- Um **instalador assinado com Developer ID divulga o nome legal do titular e o Team ID no certificado**. Isso é público por natureza e não pode ser ocultado preservando a mesma assinatura. A chave privada e as senhas não são incluídas.
- O DMG usa fundo de cor sólida: bookmarks de imagens do Finder podem gravar o nome do usuário local no `.DS_Store`. Antes da notarização, `scripts/audit-release.py` bloqueia a distribuição se encontrar caminhos de diretórios pessoais ou o nome de usuário local no conteúdo montado.
- Artefatos gerados antes dessa limpeza não devem ser publicados por engano. Após recompilar, é necessário assinar/notarizar novamente e atualizar o checksum. Publique somente o DMG final e seu SHA-256, nunca logs locais, diretórios de build ou arquivos de certificado.

### Identidade visual

Ícone original em `Resources/Keynest.icns` e prévia em `Resources/Keynest-logo.png`: tecla escura arredondada, monograma K e pulsos em verde suave. As resoluções do ícone e o fundo do DMG são reproduzíveis com `swift scripts/generate-brand.swift` e `iconutil -c icns Resources/Keynest.iconset -o Resources/Keynest.icns`. O layout do instalador é aplicado por `scripts/layout-dmg.applescript` (pode pedir autorização para controlar o Finder).

App nativo em SwiftUI para macOS 14 ou superior que acompanha os toques do teclado com sons curtos, reproduzidos na saída de áudio padrão do sistema.

## Licença

O código original do Keynest está sob [licença MIT](LICENSE). Os áudios de terceiros mantêm suas próprias licenças MIT, CC BY 4.0 e CC0, descritas em `THIRD_PARTY_NOTICES.md`, `AMBIENCE_NOTICES.md`, `NATURE_NOTICES.md` e `LOFI_NOTICES.md`. A licença do código não substitui as atribuições e condições desses arquivos.

## Recursos

- **Cherry MX Black**: gravação de switch linear, com batida mais seca.
- **Cherry MX Brown**: gravação de switch tátil, com toque equilibrado.
- **Cherry MX Blue**: gravação de switch clicky, com clique marcado.

São três modelos da família Cherry MX, não efeitos artificiais aplicados ao MX Blue.
- Volume independente, botão de prévia e ativação/pausa.
- Menu na barra do macOS para trocar o som, pausar e reabrir a janela.
- Preferências de volume, timbre e ativação salvas entre sessões.
- 12 gravações reais de teclas incluídas no app, com quatro variações por timbre e reprodução sobreposta para digitação rápida. Não há síntese de ruído ou notas. Nenhum download ou serviço externo durante o uso.
- Gravações do projeto MIT [tplai/kbsim](https://github.com/tplai/kbsim); autoria, licença e hashes em `THIRD_PARTY_NOTICES.md`. O player ajusta somente o ganho para aproximar os volumes, sem alterar o pitch.
- **Trilhas de fundo**: Chuva, Oceano, Floresta com pássaros e **Lo-fi · piano & beats**. Natureza em loops de 30 segundos e música em um ciclo de aproximadamente 49 segundos / 79 BPM. São gravações incluídas no app, sem streaming.
- Volume próprio, transição gradual entre trilhas e ao ligar/desligar. Começa desligado e em 25%; salva trilha, volume e ativação. A música recebe uma redução de ganho para aproximar o volume dos ambientes naturais.
- O ambiente continua tocando com os cliques pausados e a janela fechada, sem exigir monitoramento do teclado. A seleção também fica na barra de menus. Toca uma trilha por vez (não mistura chuva com música).
- Chuva: alex36917; oceano: Luftrum (ambos CC BY 4.0); floresta: kvgarlic (CC0), com edição Porrumentzio. Lo-fi: “Chill lofi inspired”, de omfgdude (CC0). Fontes, licenças e adaptações em `AMBIENCE_NOTICES.md`, `NATURE_NOTICES.md` e `LOFI_NOTICES.md`, incluídos no app. Links de fonte/licença também aparecem junto à trilha na interface.

## Compilar e abrir

Requer Xcode com as ferramentas de linha de comando e Swift 6 ou superior. Na raiz do repositório:

```sh
sh scripts/build-app.sh
open build/Keynest.app
```

O script compila em release e usa assinatura ad-hoc por padrão (`sh scripts/build-app.sh -`). A assinatura de distribuição é configurada por argumento, sem dados da conta fixados no código. Mantenha o app em um caminho estável e instale-o em `/Applications` **antes** de conceder as permissões. A assinatura Developer ID não substitui a notarização da Apple.

Para editar no Xcode, abra `Package.swift`. `swift run MacTap` também compila e executa, mas o bundle `.app` é o caminho recomendado para permissões do macOS.

## Primeiro uso

1. Abra o app e clique em um dos três cartões para ouvir uma prévia (não exige monitoramento).
2. Ajuste o volume; comece baixo.
3. Clique em **Autorizar no macOS**: o app liga os sons e solicita a permissão obrigatória do macOS. Autorize **Keynest** em **Ajustes do Sistema → Privacidade e Segurança → Monitoramento de Entrada**. Se a permissão continuar ausente, o botão abre esse painel. Essa autorização vale para o monitoramento global; não é necessário autorizar cada aplicativo.
4. Se o macOS solicitar, encerre completamente pelo menu **Encerrar Keynest** e abra novamente.
5. O campo **Experimente** funciona sem permissão e mesmo em pausa. Para tocar ao digitar em outros apps, ligue o interruptor e conceda a permissão. O contador mostra os eventos detectados (não confirma a saída física de áudio).

A primeira execução começa em pausa. Com o interruptor ligado, o status **Ativo** indica que o monitor global foi iniciado. Campos protegidos podem continuar bloqueados pelo macOS. Fechar a janela não encerra o app: ele sai do Dock e do alternador ⌘Tab, mas mantém os cliques, a trilha ambiente e os controles na barra de menus. Use **Abrir Keynest** nesse menu para restaurar a janela e o ícone no Dock; **Encerrar Keynest** encerra o processo e o áudio.

## Pomodoro

A seção **Pomodoro** permite configurar foco (1–180 minutos), intervalo (1–60 minutos) e de 1 a 99 ciclos ou **Ciclos sem limite**. O padrão é 25 minutos de foco, 5 de intervalo e 4 ciclos. Cada ciclo inclui foco **e intervalo**, inclusive o intervalo final: por exemplo, 4 × (25 + 5) = 120 minutos, dos quais 100 minutos de foco.

O painel destaca o tempo em um anel de progresso (verde para foco, azul suave para intervalo), com resumo de foco, pausa e total. **Ajustar sessão** expande os controles personalizados; os campos numéricos aceitam digitação ou os botões +/− e validam os limites ao confirmar/sair do campo. Tempos e ciclos ficam bloqueados enquanto a sessão está ativa.

- **Iniciar foco**, **Pausar**, **Retomar** e o botão de reiniciar (seta circular, com confirmação) controlam a sessão. A configuração fica bloqueada durante a sessão para não alterar a contagem em andamento; reiniciar descarta o progresso.
- Por padrão, o fim do foco avisa e espera **Iniciar intervalo**. Ao acabar o intervalo, espera **Iniciar foco**. Ative **Seguir automaticamente** para alternar sem confirmação.
- A interface mostra etapa, contagem regressiva, ciclo atual, total planejado e término da etapa. Sessões finitas automáticas mostram também a previsão de término de toda a sessão; pausas deslocam esse horário. No modo manual, o horário final depende das confirmações. No modo ilimitado não há horário final.
- **Um toque ao terminar** usa sons locais do macOS: Glass para fim de foco, Ping para fim de intervalo e Hero ao concluir a sessão. Não depende do volume dos cliques ou da trilha; respeita a saída e o volume do sistema. O botão de prévia (ícone de play ao lado do interruptor) testa o som da etapa atual mesmo com avisos desligados.
- Ative **Avisar por notificação** para solicitar a autorização de notificações do macOS (independente da permissão de teclado). Se negada, permita Keynest em **Ajustes do Sistema → Notificações** e tente novamente. O modo Foco/Não Perturbe e as preferências do macOS podem silenciar/ocultar banners. As notificações são visuais; os sons distintos são reproduzidos pelo app para não duplicar o aviso.
- O timer permanece ativo com a janela fechada; o menu de status mostra o tempo e permite pausar, retomar e encerrar a sessão. Cliques e ambiente são independentes do Pomodoro.
- A contagem usa datas de término, não a soma de ticks: o tempo de repouso do Mac também conta. Ao acordar, o automático recupera a etapa correta sem repetir todos os avisos perdidos; no manual, aguarda confirmação. Não há garantia de som durante o repouso. Só a próxima transição tem notificação agendada.
- Tempos e preferências são salvos. A sessão em andamento **não** é restaurada após encerrar/reabrir o app; ao encerrar normalmente, o aviso pendente é cancelado. Uma saída forçada pode deixar a próxima notificação agendada no sistema.

### Modo live do Pomodoro

Ativado por padrão, permite escolher entre **Flutuante** e **Barra de menus** em **Ajustar sessão → Modo live**, ou **Exibir timer** no menu do Keynest. São modos exclusivos: trocar não interrompe o timer e a escolha fica salva.

**Barra de menus:** mantém sempre o ícone de teclado do Keynest. Com o live na barra ativo, adiciona o tempo em dígitos monoespaçados e largura fixa de 74 pontos (inclusive ao concluir a sessão), para não deslocar os itens a cada segundo. Clique nele para iniciar a próxima etapa, pausar/retomar ou pular um intervalo. Não abre o menu automaticamente nem exibe o painel flutuante; sons e notificações continuam funcionando. Quando desativado ou sem sessão, volta ao ícone normal. Isso não é um timer no Dock.

O menu usa `NSStatusItem` e `NSMenu` nativos, separados da atualização do contador. Os submenus de teclado, ambiente, volume e modo live são montados uma vez a cada abertura: seus itens não são reconstruídos enquanto você navega. Por isso, o tempo mostrado **dentro do menu aberto** é uma fotografia do instante da abertura; a barra e o timer continuam contando normalmente. A atualização do indicador é agendada nos modos comuns do RunLoop, incluindo o modo de navegação de menus, para não congelar visualmente enquanto o menu está aberto. Se uma etapa mudar com o menu aberto, feche/reabra para obter a ação atual.

**Flutuante:** mostra um pequeno painel no canto superior direito ao iniciar uma sessão. Continua funcionando com a janela principal fechada. O botão de alfinete **Fixar no topo**, disponível tanto compacto quanto expandido, alterna entre nível flutuante (sobre outras janelas) e normal (outros apps podem cobri-lo). Começa fixado e salva a preferência; mudar a fixação não pausa nem reinicia o timer. Desafixado, o painel não é trazido à frente a cada atualização do contador. É um painel nativo do Keynest, não uma Live Activity do sistema. Você pode arrastá-lo pelo cabeçalho (ícone, título ou contador), recolher/expandir pela seta e ocultá-lo sem parar o timer. Use **Modo live do Pomodoro** na barra de menus ou **Modo live** em **Ajustar sessão** para reativar. A preferência é salva; a posição é mantida durante a execução, não entre reinicializações.

- Ao terminar foco ou intervalo, o painel expande mesmo que os avisos sonoros estejam desligados. Não ativa o app nem tira o foco do aplicativo em que você está digitando.
- **Manual:** fim do foco oferece **Iniciar intervalo** ou **Pular intervalo**; fim do intervalo oferece **Iniciar ciclo**. Iniciar recolhe o painel.
- **Automático:** a próxima etapa já está contando; o botão **Continuar intervalo/foco** apenas recolhe o painel, sem pausar nem reiniciar o tempo. Durante o intervalo também é possível pulá-lo.
- **Pular intervalo** conta o ciclo como encerrado e inicia imediatamente o próximo foco. Se era o intervalo final, conclui a sessão sem criar um ciclo extra. Essa ação também está na janela principal e no menu. O total planejado é a configuração original; a previsão de término em modo automático é reduzida ao pular uma pausa.
- Ao concluir todos os ciclos, mostra uma confirmação com opção de nova sessão; permanece visível até ocultar ou reiniciar. Encerrar/reiniciar para o estado inicial esconde o painel.
- O painel mantém 360 pontos de largura nos dois estados, com 82 pontos de altura compacto e 252 expandido. Margens internas de 20 pontos, controles de fixar/expandir de 36 × 36 e ações de 36 pontos de altura. Expande verticalmente em 0,24 segundo, preservando o canto superior, com transição de opacidade no conteúdo. O hosting SwiftUI não redimensiona a janela por conta própria.
- O painel tenta acompanhar Spaces e apps em tela cheia, sujeito às restrições de janelas do macOS. A animação de expansão respeita **Reduzir Movimento**. Interação entre monitores, tela cheia e foco de teclado precisa de teste manual.

## Idiomas / Languages

O nome **Keynest** é o mesmo em todos os idiomas. O slogan é **Encontre seu foco.** em português e **Find your focus.** em inglês.

Na seção **Idioma / Language**, escolha **Sistema / System**, **Português** ou **English**. Também há um submenu de idioma na barra superior. A preferência é salva, aplicada sem reiniciar o app e não altera o timer, os ciclos nem o áudio em andamento. Em modo Sistema, segue a primeira preferência de português ou inglês do macOS; outros idiomas têm fallback para inglês.

A localização cobre ajustes, menu de status, painel live, acessibilidade, ambientes, erros próprios do app e notificações futuras do Pomodoro. Ao trocar de idioma, a próxima notificação agendada é atualizada; notificações já entregues não mudam. Os diálogos de permissão do macOS e erros gerados pelo próprio sistema seguem o idioma do sistema. Créditos de terceiros e esta documentação mantêm seu idioma original.

Os catálogos ficam em `Sources/MacTap/Resources/Localization/{pt-BR,en}.lproj/Localizable.strings`. Novos textos devem usar `L10n.tr`, incluindo os argumentos `%@` nos dois catálogos. Datas e horários seguem o idioma escolhido. Os testes verificam os catálogos, as traduções do slogan, placeholders, persistência da escolha e preservação da sessão de foco.

## Janela de ajustes

A janela mantém a paleta escura com verde suave, cabeçalho fixo integrado e os controles nativos do macOS. As seções **Teclado** e **Ambiente** têm ativação e volume próprios. Os quatro ambientes ficam visíveis em cartões, sem abrir menus. Selecionar um teclado toca uma prévia; selecionar um ambiente troca a trilha se ela já estiver ligada.

A altura da janela pode ser ajustada. A rolagem usa um indicador discreto, preservando o controle nativo quando o sistema está configurado para mostrar sempre a barra ou aumentar o contraste. Botões têm feedback de hover, os campos indicam foco, e as animações dos controles respeitam Reduzir Movimento.

## Privacidade e limitações

O monitor global usa um `CGEventTap` somente de leitura, observa apenas eventos de tecla pressionada e não extrai caracteres nem códigos de tecla. Nada digitado em outros apps é armazenado ou enviado. O campo de teste mantém apenas seu próprio texto temporariamente em memória e o limpa ao fechar a janela; não digite informações sensíveis nele.

- A repetição automática ao segurar uma tecla é ignorada; teclas modificadoras isoladas, como Shift e Command, não produzem som.
- Campos protegidos e o modo **Secure Input** de alguns aplicativos podem impedir o monitoramento. O app não tenta contornar essas proteções.
- A saída de som segue o dispositivo padrão do macOS. Bluetooth pode acrescentar latência.
- Após recompilar com assinatura ad-hoc, o macOS pode exigir que a permissão seja removida e concedida novamente.
- O projeto não solicita permissão de microfone, não grava áudio e não usa App Sandbox. Distribuição na Mac App Store requer avaliar as regras de sandbox e monitoramento global.

## Validação

```sh
swift test
```

Os testes cobrem os 12 WAVs de teclado e as quatro trilhas de fundo empacotadas, decodificação, amplitude, duração, preservação das gravações de tecla, configuração de loop, troca/pausa/retomada com players simulados e tratamento de eventos locais sem iniciar monitoramento global. Permissões, qualidade subjetiva dos sons, dispositivos de áudio e interação visual precisam de teste manual no macOS.

Para verificar os recursos do `.app` já empacotado:

```sh
build/Keynest.app/Contents/MacOS/MacTap --check-resources
```

Se não houver som: confirme que o contador aumenta, que o volume não está zerado e que a saída de áudio correta está selecionada no macOS. Se o teste local funciona, mas outros apps não, revise a permissão e reabra o Keynest. Após recompilações ad-hoc pode ser necessário remover e autorizar a entrada novamente.

## Estrutura

- `Sources/MacTap/ContentView.swift`: janela de ajustes.
- `Sources/MacTap/Localization.swift`: idioma salvo, fallback, tradução e formatação de datas.
- `Sources/MacTap/LanguagePickerView.swift`: seletor de idioma em tempo real.
- `Sources/MacTap/SettingsComponents.swift`: paleta, controles e estilo de rolagem.
- `Sources/MacTap/MacTapApp.swift`: cenas SwiftUI e menu de status.
- `Sources/MacTap/AppLifecycle.swift`: permanência na barra de menus e visibilidade no Dock ao fechar a janela.
- `Sources/MacTap/AppModel.swift`: estado, preferências e permissões.
- `Sources/MacTap/PomodoroSession.swift`: motor puro de fases, ciclos e estimativas.
- `Sources/MacTap/PomodoroModel.swift`: timer, preferências, sons e notificações.
- `Sources/MacTap/PomodoroView.swift`: controles do Pomodoro.
- `Sources/MacTap/KeyboardMonitor.swift`: eventos locais sem permissão e observação global somente de leitura, sem reprodução dupla.
- `Sources/MacTap/ClickSound.swift`: catálogo e carregamento das gravações.
- `Sources/MacTap/Resources/KeyboardSounds/`: WAVs dos três timbres.
- `Sources/MacTap/KeyboardAudio.swift`: buffers e vozes de reprodução.
- `Sources/MacTap/AmbientAudio.swift`: player independente, loops e transições entre trilhas.
- `Sources/MacTap/AmbientSound.swift`: catálogo, créditos e licenças das trilhas.
- `Sources/MacTap/Resources/Ambience/`: chuva, oceano, floresta e lo-fi preparados para loop.
- `Resources/Info.plist`: metadados do bundle.
- `scripts/build-app.sh`: empacotamento local.
