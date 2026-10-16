/// Informações institucionais exibidas na tela "Sobre" (RF004).
///
/// Edite as listas/constantes abaixo para refletir a equipe e a disciplina.
class AppInfo {
  AppInfo._();

  static const String name = 'VALEX - Sistema de Gestão para Personal Trainers';
  static const String version = '1.0.0';
  static const String versionLabel = 'Versão $version • Beta';

  static const String objective =
      'Oferecer a personal trainers e assessorias esportivas uma ferramenta '
      'única para gerenciar alunos, montar fichas de treino inteligentes, '
      'registrar anamneses e avaliações físicas, acompanhar leads e campanhas '
      'de marketing e controlar o financeiro do negócio.';

  static const List<String> team = ['Thales de Oliveira Silva'];

  static const String institution =
      'FATEC Ribeirão Preto - Faculdade de Tecnologia de Ribeirão Preto';

  /// Deixe vazio para ocultar o item na tela.
  static const String course = '';
  static const String professor = '';

  static const List<String> features = [
    'Cadastro e acompanhamento de alunos',
    'Editor de fichas de treino com biblioteca de exercícios',
    'Anamnese e avaliação física 360°',
    'Vendas & CRM de leads',
    'Mídia & Marketing',
    'Controle financeiro',
  ];
}
