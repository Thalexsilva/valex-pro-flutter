import 'package:flutter/material.dart';

/// Carbon High-Contrast Aesthetic
/// Tokens calibrados para máxima legibilidade (WCAG AAA/AA) em modo escuro.
abstract class AppColors {
  // ── CSS Variables (Tokens de Superfície & Fundo) ───────────────────────────
  static const carbon1 = Color(
    0xFF080B10,
  ); // Fundo super escuro (Sidebars, AppBars, Modais)
  static const carbon = Color(0xFF0F131A); // Fundo principal do Scaffold
  static const carbon2 = Color(
    0xFF19202C,
  ); // Superfície de Cards e Containers (nítida separação)
  static const carbon3 = Color(
    0xFF252F40,
  ); // Superfícies elevadas, hovers e divisores ativos

  // ── Tokens Tipográficos (Contraste Aprimorado) ─────────────────────────────
  static const steel = Color(
    0xFFCBD5E1,
  ); // Texto secundário (Slate-300: Contraste > 9.5:1)
  static const steelLight = Color(
    0xFFF1F5F9,
  ); // Texto de destaque quase branco (Slate-100)
  static const steelDim = Color(
    0xFF94A3B8,
  ); // Labels, overlines, placeholders (Slate-400: Contraste > 5.8:1)
  static const muted = Color(0xFF8A99AD); // Textos secundários auxiliares

  // ── Acentos & Marca ───────────────────────────────────────────────────────
  static const blue = Color(0xFF3B82F6); // Azul elétrico vibrante
  static const blueAction = Color(0xFF2563EB); // Botões com texto branco AA
  static const blueLight = Color(
    0xFF60A5FA,
  ); // Azul luminoso para ícones e links
  static const gold = Color(0xFFF59E0B); // Dourado âmbar de alta visibilidade
  static const goldLight = Color(0xFFFDE68A); // Dourado claro
  static const paper = Color(0xFFF8FAFC); // Fundo claro (folhas de impressão)
  static const paperCard = Color(0xFFFFFFFF); // Branco puro
  static const ink = Color(0xFF0F172A); // Tinta escura para impressão em papel
  static const line = Color(0xFFE2E8F0); // Divisores claros

  /// Texto/ícones secundários sobre fundo claro (`paper`/`paperCard`).
  /// `steel`/`steelDim`/`muted` só têm contraste adequado sobre fundos
  /// escuros (`carbon*`) — usar este token nas páginas "de papel" do editor.
  static const paperMuted = Color(0xFF475569);
  static const paperBlue = Color(0xFF1D4ED8);
  static const paperGold = Color(0xFF92400E);
  static const paperGreen = Color(0xFF047857);

  // ── Status Semânticos (Alta Luminância) ───────────────────────────────────
  static const emerald = Color(0xFF10B981); // Verde sucesso / Pago
  static const green = emerald;
  static const amber = Color(0xFFF59E0B); // Amarelo aviso / Pendente
  static const crimson = Color(0xFFEF4444); // Vermelho erro / Atrasado
  static const crimsonText = Color(
    0xFFF87171,
  ); // Erro em texto sobre card escuro

  // Helpers com opacidade para chips de status (Fundo legível + Borda)
  static Color paidBg = const Color(0xFF064E3B).withValues(alpha: 0.5);
  static Color pendingBg = const Color(0xFF78350F).withValues(alpha: 0.5);
  static Color overdueBg = const Color(0xFF7F1D1D).withValues(alpha: 0.5);

  // ── Radii ─────────────────────────────────────────────────────────────────
  static const radiusCard = 16.0; // --radius
  static const radiusBtn = 10.0; // --radius-btn
  static const radiusSm = 8.0; // --radius-sm
  static const radiusXs = 6.0; // --radius-xs

  // ── Backward Compatibility Aliases (Do not remove) ────────────────────────
  static const vibrantBlue = blue;
  static const highlightBlue = blueLight;
  static const metallicGold = gold;
  static const onSurface = paperCard;
  static const onSurfaceVariant = steel;
  static const outline = steelDim;
  static const error = crimson;
  static const elevatedCarbon = carbon2;
  static const surface = carbon1;
  static const surfaceContainerLowest = carbon1;
  static const surfaceContainerLow = carbon1;
  static const surfaceContainer = carbon2;
  static const surfaceContainerHigh = carbon3;
  static const outlineVariant = carbon3;
  static const secondary = gold;
  static const densityComfortable = 16.0;
  static const densityCompact = 8.0;
  static const containerPadding = 24.0;
  static const dividerColor = Color(0xFF283548);
}
