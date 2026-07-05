import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';

class ProdutoSearchBar extends StatefulWidget {
  const ProdutoSearchBar({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<ProdutoSearchBar> createState() => _ProdutoSearchBarState();
}

class _ProdutoSearchBarState extends State<ProdutoSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant ProdutoSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != _controller.text && _debounce?.isActive != true) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;
    final theme = Theme.of(context);

    return SizedBox(
      height: t.minTouchTarget + s.sm,
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        style: theme.textTheme.erpBody.copyWith(color: t.textPrimary),
        decoration: InputDecoration(
          hintText: 'Pesquisar produto...',
          hintStyle: theme.textTheme.erpBody.copyWith(color: t.textMuted),
          prefixIcon: Icon(Icons.search, color: t.textMuted, size: t.iconSm),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: t.textMuted, size: t.iconSm),
                  onPressed: _clear,
                )
              : null,
          filled: true,
          fillColor: t.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radius3xl),
            borderSide: BorderSide(color: t.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radius3xl),
            borderSide: BorderSide(color: t.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(t.radius3xl),
            borderSide: BorderSide(color: t.brandBlue, width: 2),
          ),
          contentPadding: t.density.inputPadding,
        ),
      ),
    );
  }
}
