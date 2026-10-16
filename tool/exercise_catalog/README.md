# Biblioteca de exercícios

Catálogo no Supabase com 2.029 exercícios e 40 métodos. Os 152 títulos usados
anteriormente pelo VALEX continuam disponíveis; 97 equivalências explícitas
reaproveitam os metadados importados. Os demais 55 registros locais complementam
os 876 da base original. A fonte de GIFs acrescenta 1.098 exercícios sem
equivalente confirmado em português. Nenhuma ficha salva é migrada ou renomeada.

## Fontes fixadas

- [free-exercise-db](https://github.com/yuhonas/free-exercise-db), revisão
  `a859101d633a01c4a1a920d6a8ce41dabba0705f`: 876 registros. Metadados originais,
  IDs e nomes alternativos em inglês. Licença Unlicense, em `sources/LICENSE-original.md`.
- [exercicios-bd-ptbr](https://github.com/gugeldev/exercicios-bd-ptbr), revisão
  `6bb9118e46cf8d0ee98b42e0285bae5036d04a19`: 873 traduções, versão parcial
  (nomes e instruções em português, chaves de classificação em inglês).
  Licença CC0-1.0, em `sources/LICENSE-ptbr.txt`.
- As visualizações Airtable fornecidas (`shrkXVfPv0fsD6qES` e
  `shrQRpHlbOtxBGSWT`, base `appUvkPDv4gZdjzyr`) exibem os mesmos 873 exercícios
  e apontam para o projeto original. Não foram importadas como fonte adicional.

Os arquivos JSON originais estão em `sources/`. Os hashes SHA-256 e contagens
estão em `manifest.json`. O cache permite reutilizar o conteúdo já consultado sem rede; imagens externas não
são baixadas nem redistribuídas. As licenças acima acompanham os dados.

## Geração

Execute na raiz do app:

```sh
python tool/exercise_catalog/generate.py
python tool/exercise_catalog/build_media.py
python tool/exercise_catalog/deduplicate_gymvisual.py
```

Os scripts usam apenas a biblioteca padrão do Python e escrevem
`tool/exercise_catalog/exercises.json`. Os métodos são mantidos em
`training-methods.json`. Esses arquivos servem à importação e aos testes e não
são incluídos no pacote Flutter. As traduções são unidas por ID, nunca por
semelhança textual. As equivalências com o legado são explícitas; correspondências
exatas e únicas também são aceitas. Variantes ambíguas permanecem separadas.
IDs e títulos finais devem ser únicos. As categorias e equipamentos são
traduzidos por mapas verificáveis.

Os três exercícios novos com kettlebell receberam traduções locais, identificadas
por `Free Exercise DB · tradução VALEX`. Quatro pares de nomes homônimos receberam
nomes distintos conforme o movimento original. Por exemplo, trote e corrida na
esteira permanecem exercícios separados.

Cinco registros nas duas fontes não incluem instruções: `Iron_Cross`,
`One-Arm_Kettlebell_Swings`, `Push_Press`, `Side_Bridge` e `Side_Jackknife`.
`Side_Bridge` reaproveita a orientação local existente; os outros quatro exibem
explicitamente a ausência de orientação. Nenhuma instrução foi inventada para
preencher essas lacunas. O restante do conteúdo foi importado, sem afirmar revisão
técnica individual de todas as traduções.

O campo `cue` guarda uma orientação curta para a ficha. O passo a passo integral
fica em `instructions` para consulta na biblioteca. O nome anterior e a ordem
inicial dos 152 exercícios são preservados, inclusive para os consumidores que
selecionam itens por título ou pela ordem do catálogo.

## Mídia de execução

Os 873 registros da revisão original que têm imagens trazem exatamente
`<id>/0.jpg` e `<id>/1.jpg`. O aplicativo monta URLs da revisão fixada acima,
mostra as duas posições na biblioteca e salva a primeira na ficha do aluno.
As imagens permanecem no repositório de origem; dependem de conexão para abrir.
Os três registros novos de kettlebell e os registros exclusivos VALEX não têm
essas imagens na fonte. Nenhum dos dois snapshots importados contém GIFs ou
vídeos. URLs HTTPS de GIF ou vídeo cadastradas em exercícios são exibidas como
animação ou link de reprodução, respectivamente.

Os GIFs do [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
são tratados como fonte de mídia separada, fixada na revisão
`7455efae41b330c265e7cd4b78dfa848e7ce5ebd`. `build_media.py --refresh`
salva apenas metadados necessários em `sources/gymvisual-media.json` e gera
1.324 registros em lotes SQL dentro de `.dart_tool/catalog-media/`. Os GIFs e
miniaturas não entram no pacote Flutter: o Supabase guarda URLs e a interface
busca uma correspondência ao abrir o exercício. Há 130 correspondências únicas
por nome inglês e mais 99 vínculos revisados em
`sources/gymvisual-equivalences.json`. Desses, 96 removem entradas repetidas;
os GIFs permanecem vinculados ao exercício preservado. Os outros 1.098
exercícios ficam no catálogo com texto original em inglês e seus GIFs.
O treinador ainda pode trocar uma demonstração pela busca.
A pasta `videos/` da fonte contém GIFs, não vídeos MP4.

Essa mídia pertence à Gym visual, não à licença MIT dos metadados. O app mostra
`© Gym visual — https://gymvisual.com/` junto aos GIFs. A licença de uso da mídia
deve ser mantida pelo operador do VALEX, conforme o `NOTICE.md` da fonte.

## Publicação e carregamento

A migração `public_training_catalog` cria três tabelas de referência com RLS e
acesso de leitura para `anon` e `authenticated`; escrita exige acesso administrativo.
O aplicativo não recebe credenciais administrativas. Dados dos alunos e fichas
salvas continuam nas tabelas existentes.

`prepare_seed.py` gera lotes SQL em `.dart_tool/catalog-seed/<versão>/`: primeiro cria uma
versão inativa, depois envia exercícios e métodos. O lote de ativação confere as
contagens e troca a versão ativa em uma transação. Versões anteriores permanecem
disponíveis para consultas em andamento e eventual rollback. Execute os lotes na
ordem usando uma conexão administrativa; não coloque esses arquivos nos assets.

Ao abrir a biblioteca, `CatalogService` consulta a versão ativa e baixa somente
os resumos (páginas de 500) e os métodos quando necessário. A busca e os filtros
usam esse índice em memória para responder sem uma requisição a cada tecla.
As instruções completas são buscadas individualmente ao abrir “Orientações e
observações”. Até 100 exercícios consultados ficam no cache de detalhes.
O cache inclui a versão e o projeto, e não armazena dados pessoais. Falhas de
rede preservam a cópia completa anterior; ausência de cache apresenta nova tentativa.

Verificação de leitura pública e equivalência integral do conteúdo, sem alterações:

```sh
python tool/exercise_catalog/verify_remote.py
python tool/exercise_catalog/verify_media.py
```

Usa apenas URL e chave pública de `config/beta.json`. Não cria usuários nem fichas.
