import 'package:flutter/material.dart';
import '../repositories/anamnese_repository.dart';

class PrivateDocumentImage extends StatefulWidget {
  final String reference;
  final BoxFit fit;
  const PrivateDocumentImage({
    super.key,
    required this.reference,
    this.fit = BoxFit.contain,
  });

  @override
  State<PrivateDocumentImage> createState() => _PrivateDocumentImageState();
}

class _PrivateDocumentImageState extends State<PrivateDocumentImage> {
  late Future<Uri> _uri;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _uri = AnamneseRepository().documentUri(widget.reference);
  }

  @override
  void didUpdateWidget(covariant PrivateDocumentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) _reload();
  }

  Widget _error() => Center(
    child: IconButton(
      tooltip: 'Recarregar foto',
      icon: const Icon(Icons.refresh),
      onPressed: () => setState(_reload),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Uri>(
    future: _uri,
    builder: (context, snapshot) {
      if (snapshot.hasError) return _error();
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return Image.network(
        snapshot.data.toString(),
        fit: widget.fit,
        errorBuilder: (_, error, stack) => _error(),
      );
    },
  );
}
