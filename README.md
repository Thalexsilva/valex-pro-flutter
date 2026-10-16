# VALEX Pro

Aplicativo multiplataforma em **Flutter/Dart** para gestão de personal trainers: cadastro e
acompanhamento de alunos, montagem de fichas de treino, biblioteca de modelos, funil de vendas,
ferramentas de marketing e controle financeiro.

Projeto Prático – Parte 1 · **FATEC Ribeirão Preto** · Desenvolvido por **Thales de Oliveira Silva**.

## Requisitos atendidos

| Requisito | Onde está |
| --- | --- |
| RF001 – Login | `lib/views/auth/login_view.dart` (validações em `lib/utils/validators.dart`) |
| RF002 – Cadastro de usuário | `lib/views/auth/sign_up_view.dart` |
| RF003 – Esqueceu a senha | `lib/views/auth/password_recovery_view.dart` |
| RF004 – Sobre | `lib/views/about/about_view.dart` (dados em `lib/config/app_info.dart`) |
| RF005 – Perfil do usuário | `lib/views/profile/profile_view.dart` + `lib/controllers/user_profile_controller.dart` |
| RF006 – Funcionalidades do tema | ver tabela abaixo (uma interface por arquivo Dart) |
| RF007 – Listagem de dados | `ListView.builder` nas faturas de `lib/views/finance/finance_view.dart` (também `GridView.builder` no menu "Mais") |

### Funcionalidades específicas (RF006)

| # | Funcionalidade | Arquivo |
| --- | --- | --- |
| 1 | Visão Geral (indicadores e atividade dos alunos) | `lib/views/dashboard/dashboard_view.dart` |
| 2 | Alunos (lista e detalhe com anamnese e financeiro) | `lib/views/students/students_view.dart`, `lib/views/students/student_detail_view.dart` |
| 3 | Editor de fichas de treino | `lib/views/editor/editor_view.dart` |
| 4 | Biblioteca de modelos e exercícios | `lib/views/presets/presets_view.dart` |
| 5 | Vendas & CRM (funil de leads) | `lib/views/sales/sales_view.dart` |
| 6 | Mídia & Marketing | `lib/views/marketing/marketing_view.dart` |
| 7 | Financeiro (faturas, assinaturas, planos, caixa) | `lib/views/finance/finance_view.dart` |

### Requisitos não funcionais

- **Flutter SDK e Dart** (Flutter 3.47, Dart 3.13).
- **Gerenciamento de estado com `ChangeNotifier`**: `UserProfileController`, `StudentContextService`,
  `FinanceRepository`, `CatalogService` e `WorkoutAutosaveController`. As telas escutam esses objetos
  com `ListenableBuilder` ou `addListener` e são redesenhadas quando `notifyListeners()` é chamado.
- **Material Design**: tema próprio em `lib/theme/`, componentes Material 3.
- **Navegação**: `lib/views/main_navigation_view.dart` usa `NavigationBar` no celular,
  `NavigationRail` em telas largas e `Navigator.push` para cadastro, recuperação de senha e detalhes.

## Estrutura

```text
lib/
  config/        configuração do Supabase e dados da tela Sobre
  controllers/   ChangeNotifiers de perfil e salvamento automático
  models/        modelos de domínio (aluno, ficha, financeiro, vendas...)
  repositories/  acesso aos dados (Supabase)
  services/      serviços de estado, PDF, catálogo e sessão
  theme/         cores, tipografia e animações
  utils/         validadores e formatadores
  views/         uma pasta por funcionalidade (telas)
  widgets/       componentes reutilizáveis
supabase/
  migrations/    esquema do banco (PostgreSQL + RLS)
  functions/     Edge Functions
  seed.sql       dados fictícios para demonstração
test/            testes unitários, de widget e ponta a ponta
tool/exercise_catalog/  fontes e scripts do catálogo de exercícios (também usados nos testes)
```

## Como executar

O aplicativo usa o [Supabase](https://supabase.com) como backend (autenticação e banco). O
repositório traz tudo para rodar um Supabase **local**, já com dados fictícios.

### Pré-requisitos

- Flutter 3.47 ou superior (`flutter doctor`)
- Docker Desktop em execução
- Node.js (para usar a CLI do Supabase via `npx`)

### Passo a passo

```bash
npx supabase start
```

```bash
flutter pub get
```

```bash
flutter run -d chrome --dart-define-from-file=config/local.json
```

Conta de demonstração criada pelo `supabase/seed.sql` (existe apenas no Supabase local):

- **E-mail:** `treinador@valex.local`
- **Senha:** `Valex@2026`

Na tela de login, selecione **Instrutor**. Também é possível criar uma nova conta pelo botão
**Criar conta**. Os e-mails de recuperação de senha chegam na caixa local do Mailpit, em
<http://127.0.0.1:54324>.

Para voltar o banco ao estado inicial:

```bash
npx supabase db reset
```

Sem `--dart-define-from-file` o app abre normalmente e mostra as validações das telas de
autenticação, mas não consegue autenticar por não ter um backend configurado.

## Testes

```bash
flutter test
```

## Tecnologias

Flutter · Dart · Material Design · ChangeNotifier · Supabase (Auth, PostgreSQL, RLS, Edge Functions)
· pdf/printing · fl_chart · shared_preferences
