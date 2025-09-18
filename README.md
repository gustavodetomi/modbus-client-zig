# GTK4 com Zig - Aplicação Demo para Windows 11

Este projeto demonstra como criar uma aplicação GTK4 usando a linguagem de programação Zig no Windows 11.

## 📋 Pré-requisitos

- Windows 11
- PowerShell com privilégios de administrador
- Conexão com a internet para downloads

## 🚀 Instalação Rápida

Siga estes passos na ordem para configurar o ambiente completo:

### 1. Instalar Zig e Dependências Base

Execute como **administrador**:

```powershell
.\install_zig_deps.ps1
```

Este script irá:
- Instalar Chocolatey (se necessário)
- Instalar Zig
- Instalar Git
- Instalar MSYS2
- Instalar Visual Studio Build Tools
- Instalar LLVM

**⚠️ IMPORTANTE**: Reinicie o terminal após este passo!

### 2. Instalar Dependências GTK4

Execute como **administrador**:

```powershell
.\install_gtk4_deps.ps1
```

Este script irá:
- Instalar GTK4 via MSYS2
- Instalar todas as bibliotecas necessárias (GLib, Cairo, Pango, etc.)
- Configurar variáveis de ambiente
- Criar arquivo de configuração `gtk4_config.txt`

**⚠️ IMPORTANTE**: Reinicie o terminal após este passo!

### 3. Compilar a Aplicação

```powershell
.\build.ps1
```

Ou para executar imediatamente após compilar:

```powershell
.\build.ps1 -Run
```

## 🎯 Scripts Disponíveis

### `install_zig_deps.ps1`

**Uso**: `.\install_zig_deps.ps1 [-Force]`

- `-Force`: Força reinstalação mesmo se já estiver instalado

### `install_gtk4_deps.ps1`

**Uso**: `.\install_gtk4_deps.ps1 [-Force]`

- `-Force`: Força reinstalação das dependências

### `build.ps1`

**Uso**: `.\build.ps1 [-BuildType <tipo>] [-Clean] [-Run] [-Verbose]`

**Parâmetros**:
- `-BuildType`: Tipo de build (`Debug`, `Release`, `ReleaseOptimized`)
- `-Clean`: Limpa build anterior antes de compilar
- `-Run`: Executa a aplicação após compilar
- `-Verbose`: Mostra saída detalhada da compilação

**Exemplos**:
```powershell
# Build debug (padrão)
.\build.ps1

# Build release e executar
.\build.ps1 -BuildType Release -Run

# Limpar e rebuild com saída verbose
.\build.ps1 -Clean -Verbose

# Build otimizado
.\build.ps1 -BuildType ReleaseOptimized
```

## 📁 Estrutura do Projeto

```
zig-gtk4/
├── src/
│   └── main.zig                 # Código fonte principal
├── build/
│   └── bin/
│       ├── gtk4-app.exe        # Executável compilado
│       └── *.dll               # DLLs necessárias
├── install_zig_deps.ps1        # Instalador do Zig
├── install_gtk4_deps.ps1       # Instalador GTK4
├── build.ps1                   # Script de build
├── gtk4_config.txt             # Configurações GTK4
└── README.md                   # Este arquivo
```

## 🖥️ Funcionalidades da Aplicação

A aplicação demonstra:

- ✅ **Janela GTK4 básica** com título e tamanho configurável
- ✅ **Labels** com texto simples e formatado (markup)
- ✅ **Botões** com callbacks e eventos
- ✅ **Campo de entrada de texto** com placeholder
- ✅ **Layout responsivo** usando GTK Box containers
- ✅ **Separadores visuais** para organização
- ✅ **Contador de cliques** para demonstrar estado
- ✅ **Informações do sistema** (OS, arquitetura, versão Zig)
- ✅ **Tratamento de eventos** (cliques, mudança de texto, fechamento)
- ✅ **Emojis** para interface mais amigável

## 🔧 Solução de Problemas

### Erro: "Zig não encontrado"
- Execute `install_zig_deps.ps1` como administrador
- Reinicie o terminal
- Verifique se `zig version` funciona

### Erro: "GTK4 não encontrado"
- Execute `install_gtk4_deps.ps1` como administrador
- Reinicie o terminal
- Verifique se `C:\msys64\mingw64\lib` existe

### Erro: "pkg-config não encontrado"
- Reinicie o terminal
- Execute `refreshenv` (se usando Chocolatey)
- Verifique se `C:\msys64\mingw64\bin` está no PATH

### Erro de compilação: "biblioteca não encontrada"
- Verifique se todas as DLLs estão em `C:\msys64\mingw64\bin`
- Execute `.\build.ps1 -Clean` para rebuild completo
- Verifique se o MSYS2 foi atualizado corretamente

### DLLs faltando na execução
- O script de build copia automaticamente as DLLs necessárias
- Se ainda houver erro, copie manualmente de `C:\msys64\mingw64\bin`

## 📚 Desenvolvimento

Para expandir a aplicação:

1. **Modificar `src/main.zig`** - Adicionar novos widgets e funcionalidades
2. **Atualizar `build.ps1`** - Se precisar de novas bibliotecas
3. **Usar `gtk4_config.txt`** - Para referência de paths e configurações

### Bibliotecas GTK4 Disponíveis

- `gtk-4` - Widgets principais do GTK4
- `glib-2.0` - Biblioteca base do GLib
- `gobject-2.0` - Sistema de objetos
- `cairo` - Renderização 2D
- `pango` - Layout de texto
- `gdk_pixbuf` - Manipulação de imagens
- `gio` - I/O e aplicações

## 🎨 Recursos GTK4

A aplicação pode ser expandida com:

- **Menus e barras de ferramentas**
- **Diálogos de arquivo**
- **Tabelas e listas**
- **Gráficos e desenho customizado**
- **Integração com sistema de arquivos**
- **Suporte a temas**
- **Internacionalização**

## 📄 Licença

Este projeto é fornecido como exemplo educacional. Use livremente para aprender e desenvolver suas próprias aplicações GTK4 com Zig.

## 🔗 Links Úteis

- [Documentação Zig](https://ziglang.org/documentation/)
- [Documentação GTK4](https://docs.gtk.org/gtk4/)
- [MSYS2](https://www.msys2.org/)
- [Chocolatey](https://chocolatey.org/)

