import 'package:flutter/material.dart';

import '../controllers/paginated_list_controller.dart';
import '../utils/feed_grid.dart';
import 'empty_state.dart';

class PaginatedPostGrid<T> extends StatefulWidget {
  const PaginatedPostGrid({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.padding,
    this.emptyMessage = 'Nothing here yet.',
    this.emptyIcon = Icons.local_fire_department_outlined,
    this.action,
    this.onRefresh,
    this.childAspectRatio,
  });

  final PaginatedListController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final EdgeInsetsGeometry? padding;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? action;
  final Future<void> Function()? onRefresh;
  final double? childAspectRatio;

  @override
  State<PaginatedPostGrid<T>> createState() => _PaginatedPostGridState<T>();
}

class _PaginatedPostGridState<T> extends State<PaginatedPostGrid<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedPostGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 240) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (controller.loading && controller.items.isEmpty) {
      return const LoadingState();
    }

    if (controller.error != null && controller.items.isEmpty) {
      return ErrorState(
        message: controller.error!,
        onRetry: controller.reload,
      );
    }

    if (controller.items.isEmpty) {
      return EmptyState(
        message: widget.emptyMessage,
        icon: widget.emptyIcon,
        action: widget.action,
      );
    }

    final crossAxisCount = feedGridCrossAxisCount(context);
    final spacing = feedGridSpacing(context);
    final aspectRatio = widget.childAspectRatio ?? feedGridChildAspectRatio(context);
    final itemCount = controller.items.length + (controller.hasMore ? 1 : 0);

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? controller.reload,
      color: Theme.of(context).colorScheme.secondary,
      child: GridView.builder(
        controller: _scrollController,
        physics: ScrollConfiguration.of(context).getScrollPhysics(context),
        padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 4, 16, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: aspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index >= controller.items.length) {
            return const Center(child: CircularProgressIndicator());
          }
          return widget.itemBuilder(context, controller.items[index]);
        },
      ),
    );
  }
}
