# Modbus Client com GTK4 e Zig

Cliente Modbus com interface gráfica desenvolvido em Zig usando GTK4 para Windows.

## Pré-requisitos

- Windows 11
- PowerShell com privilégios de administrador

## Configuração

Execute em ordem como administrador:

1. Instalar Zig e dependências:
```powershell
.\scripts\win\install_zig_deps.ps1
```

2. Instalar GTK4:
```powershell
.\scripts\win\install_gtk4_deps.ps1
```

Reinicie o terminal após cada instalação.

## Compilação e Execução

### Usando Zig (recomendado)

```bash
# Debug simples
zig build

# Debug com watch (recompila ao detectar mudanças)
zig build dev --watch

# Build de produção
zig build production

# Executar após compilar
zig build && .\zig-out\bin\modbus-client.exe
```

### Desenvolvimento com scripts

```powershell
# Modo watch ativo (recomendado para desenvolvimento)
.\dev.ps1

# Build e executar automaticamente
.\dev.ps1 -Run
```

### Usando PowerShell (legado)

```powershell
# Debug
.\scripts\win\build.ps1 -Run

# Produção  
.\scripts\win\build-production.ps1

# Desenvolvimento
.\scripts\win\dev.ps1
```

## Estrutura

```
src/
  main.zig              # Código principal
build.zig               # Build script nativo
scripts/win/            # Scripts PowerShell auxiliares
zig-out/bin/            # Executáveis gerados
```

## Funcionalidades

- Interface GTK4 responsiva
- Widgets básicos (botões, campos de texto, labels)
- Gerenciamento de estado
- Tratamento de eventos
- Informações do sistema

## Desenvolvimento

O arquivo `build.zig` configura automaticamente:
- Detecção do MSYS2
- Linking das bibliotecas GTK4
- Cópia das DLLs necessárias
- Configurações debug/release

Para modificar a interface, edite `src/main.zig`.

## Troubleshooting

**Erro: GTK4 não encontrado**
- Verifique se MSYS2 está instalado em C:\msys64
- Execute o script install_gtk4_deps.ps1

**Erro: Zig não encontrado**
- Execute install_zig_deps.ps1 
- Reinicie o terminal

**DLLs faltando**
- Execute `zig build` que copia automaticamente as DLLs
- Ou use os scripts PowerShell que fazem isso também

