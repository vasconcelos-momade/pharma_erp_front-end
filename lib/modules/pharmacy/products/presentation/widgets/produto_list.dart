import 'package:flutter/material.dart';
import '../../../../../core/theme/design_tokens.dart';
import '../../../../../core/theme/extensions.dart';
import '../../../../../core/theme/spacing.dart';
import '../../domain/entities/product.dart';
import 'produto_card.dart';

class ProdutoList extends StatefulWidget {
  const ProdutoList({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoading,
    required this.onLoadMore,
    required this.onItemTap,
    required this.onItemAction,
  });

  final List<Product> items;
  final bool hasMore;
  final bool isLoading;
  final VoidCallback onLoadMore;
  final void Function(Product) onItemTap;
  final void Function(Product, String) onItemAction;

  @override
  State<ProdutoList> createState() => _ProdutoListState();
}

class _ProdutoListState extends State<ProdutoList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.pharmaTokens;
    final s = context.spacing;

    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.all(s.md),
      itemCount: widget.items.length + 1,
      separatorBuilder: (_, _) => SizedBox(height: s.sm),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          if (widget.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (!widget.hasMore && widget.items.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Fim da lista',
                  style: Theme.of(context).textTheme.erpCaption.copyWith(
                        color: t.textMuted,
                      ),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final product = widget.items[index];
        return ProdutoCard(
          product: product,
          onTap: () => widget.onItemTap(product),
          onAction: (action) => widget.onItemAction(product, action),
        );
      },
    );
  }
}
