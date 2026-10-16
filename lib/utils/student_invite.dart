import '../config/supabase_config.dart';
import '../models/student_model.dart';

/// Mensagens enviadas ao aluno pelo WhatsApp. O portal exige uma conta criada
/// com o mesmo e-mail cadastrado pelo instrutor; não há link com token.
class StudentInvite {
  StudentInvite._();

  static const String portalUrl = SupabaseConfig.passwordRecoveryRedirect;

  static String _accessLine(Student student) => student.email.trim().isEmpty
      ? 'Antes de entrar, me envie o seu e-mail para eu liberar o seu acesso.'
      : 'Entre (ou crie sua conta) com o e-mail *${student.email.trim()}*.';

  static String firstAssessment(Student student) =>
      '''Olá, ${student.name}! 👋

Para montarmos o seu treino com segurança, preencha a sua *Avaliação 360°* no portal do aluno:

🔗 $portalUrl

${_accessLine(student)} A avaliação abre logo após o login, leva poucos minutos e você pode salvar e continuar depois.''';

  static String reassessment(Student student) =>
      '''Olá, ${student.name}! 👋

Solicitei uma *nova Avaliação 360°* para atualizar suas metas, composição corporal e ajustes da sua ficha.

🔗 $portalUrl

${_accessLine(student)} A reavaliação aparece assim que você entrar.''';
}
