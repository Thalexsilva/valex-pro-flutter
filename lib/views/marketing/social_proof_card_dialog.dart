import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class SocialProofCardDialog extends StatefulWidget {
  const SocialProofCardDialog({super.key});

  @override
  State<SocialProofCardDialog> createState() => _SocialProofCardDialogState();
}

class _SocialProofCardDialogState extends State<SocialProofCardDialog> {
  int _cardType =
      0; // 0: Evolução Aluno, 1: Comparativo de ROI, 2: Garantia Blindada

  // Dados Aluno
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _metric1Controller = TextEditingController();
  final TextEditingController _metric2Controller = TextEditingController();
  final TextEditingController _protocolController = TextEditingController();

  // Dados ROI
  final TextEditingController _roiWasteController = TextEditingController();
  final TextEditingController _roiInvestmentController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _metric1Controller.dispose();
    _metric2Controller.dispose();
    _protocolController.dispose();
    _roiWasteController.dispose();
    _roiInvestmentController.dispose();
    super.dispose();
  }

  void _copyCardText() {
    String textToCopy = '';
    if (_cardType == 0) {
      textToCopy =
          '''
🔥 RESULTADO REAL DO PROTOCOLO VALEX

Aluno(a): ${_nameController.text}
⏱ Tempo de Acompanhamento: ${_durationController.text}
📊 Resultados Atingidos:
  • ${_metric1Controller.text}
  • ${_metric2Controller.text}
🛡 Método: ${_protocolController.text}

Quer um planejamento individualizado como esse?
Mande uma mensagem no meu WhatsApp e garanta sua vaga! 🚀
''';
    } else if (_cardType == 1) {
      textToCopy =
          '''
💡 QUANTO VALE O SEU TEMPO E RESULTADO?

❌ Treinar sozinho(a): ${_roiWasteController.text} e meses sem progresso.
✅ Consultoria Personalizada VALEX: ${_roiInvestmentController.text} com periodização científica.

O que você prefere: continuar tentando adivinhar seus treinos ou ter acompanhamento profissional de verdade?
Clique no link da bio e comece hoje!
''';
    } else {
      textToCopy = '''
🛡️ GARANTIA BLINDADA DE 15 DIAS

Se nos primeiros 15 dias de treino você sentir que o método não é para você ou não se adaptar à planilha individualizada, eu devolvo 100% do seu investimento.

Sem letras miúdas. O risco é todo meu.
''';
    }

    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto do cartão copiado para Stories / WhatsApp!'),
        backgroundColor: AppColors.emerald,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.carbon1,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.carbon2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppColors.gold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Criar Imagens Prontas para Stories',
                          style: AppTheme.headlineSm(),
                        ),
                        Text(
                          'Mostre a evolução dos seus alunos e quebre a objeção de preço no Instagram',
                          style: AppTheme.bodySm(color: AppColors.steelDim),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.steel),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Segmented Type Selector
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.carbon2.withValues(alpha: 0.5),
              child: Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: '🏆 Antes & Depois',
                      isSelected: _cardType == 0,
                      onTap: () => setState(() => _cardType = 0),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _TypeButton(
                      label: '💰 Pizza vs Treino',
                      isSelected: _cardType == 1,
                      onTap: () => setState(() => _cardType = 1),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _TypeButton(
                      label: '🛡️ Garantia 15 Dias',
                      isSelected: _cardType == 2,
                      onTap: () => setState(() => _cardType = 2),
                    ),
                  ),
                ],
              ),
            ),

            // Content Scroll
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Visual Preview Card (Mockup do Cartão)
                  _buildVisualCardPreview(),
                  const SizedBox(height: 16),

                  // Campos de Customização Rápida
                  const Text(
                    'Editar Informações do Cartão:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.steel,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_cardType == 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Nome do Aluno(a)',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Tempo de Consultoria',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _metric1Controller,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Resultado 1 (Ex: Peso)',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _metric2Controller,
                            style: AppTheme.inputText(),
                            decoration: const InputDecoration(
                              labelText: 'Resultado 2 (Ex: Medidas)',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _protocolController,
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Protocolo / Método Utilizado',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else if (_cardType == 1) ...[
                    TextFormField(
                      controller: _roiWasteController,
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Desperdício Comum (Sem Consultoria)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _roiInvestmentController,
                      style: AppTheme.inputText(),
                      decoration: const InputDecoration(
                        labelText: 'Investimento Inteligente (Com Você)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.carbon2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'O cartão de garantia reforça a segurança psicológica do lead, eliminando a hesitação na compra e aumentando o fechamento em até 35%.',
                        style: TextStyle(color: AppColors.steel, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.carbon2,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyCardText,
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text(
                        'COPIAR TEXTO FORMATADO P/ WHATSAPP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualCardPreview() {
    if (_cardType == 0) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B2332), Color(0xFF10141C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.blue.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CASE DE SUCESSO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blueLight,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    '⏱ ${_durationController.text}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _nameController.text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.carbon3.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RESULTADO',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.steelDim,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _metric1Controller.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.carbon3.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.blueLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EVOLUÇÃO',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.steelDim,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _metric2Controller.text,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.blueLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.carbon2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🛡 ${_protocolController.text}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.steel,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else if (_cardType == 1) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF201B14), Color(0xFF121419)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUAL O REAL CUSTO DO SEU RESULTADO?',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 18,
                color: AppColors.gold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cancel_rounded,
                    color: AppColors.crimson,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _roiWasteController.text,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _roiInvestmentController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.carbon2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald, width: 1.5),
        ),
        child: Column(
          children: const [
            Icon(
              Icons.verified_user_rounded,
              color: AppColors.emerald,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'GARANTIA INCONDICIONAL DE 15 DIAS',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Experimente o método por 15 dias. Se não se adaptar, devolvo 100% do seu dinheiro.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.steel,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : AppColors.carbon3,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : AppColors.steel,
            ),
          ),
        ),
      ),
    );
  }
}
