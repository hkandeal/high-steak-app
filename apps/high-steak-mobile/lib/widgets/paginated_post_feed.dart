import 'package:flutter/material.dart';

import '../controllers/paginated_list_controller.dart';
import '../utils/feed_layout_controller.dart';
import 'paginated_list_view.dart';
import 'paginated_post_grid.dart';

typedef PostFeedItemBuilder<T> = Widget Function(
  BuildContext context,
  T item, {
  required bool dense,
});

class PaginatedPostFeed<T> extends StatelessWidget {
  const PaginatedPostFeed({
    super.key,
    required this.controller,
    required this.layout,
    required this.itemBuilder,
    this.padding,
    this.emptyMessage = 'Nothing here yet.',
    this.emptyIcon = Icons.local_fire_department_outlined,
    this.action,
    this.onRefresh,
    this.gridChildAspectRatio,
  });

  final PaginatedListController<T> controller;
  final FeedLayoutController layout;
  final PostFeedItemBuilder<T> itemBuilder;
  final EdgeInsetsGeometry? padding;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? action;
  final Future<void> Function()? onRefresh;
  final double? gridChildAspectRatio;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: layout,
      builder: (context, _) {
        if (layout.useGrid) {
          return PaginatedPostGrid<T>(
            controller: controller,
            padding: padding,
            emptyMessage: emptyMessage,
            emptyIcon: emptyIcon,
            action: action,
            onRefresh: onRefresh,
            childAspectRatio: gridChildAspectRatio,
            itemBuilder: (context, item) =>
                itemBuilder(context, item, dense: true),
          );
        }

        return PaginatedListView<T>(
          controller: controller,
          padding: padding,
          emptyMessage: emptyMessage,
          emptyIcon: emptyIcon,
          action: action,
          onRefresh: onRefresh,
          itemBuilder: (context, item) =>
              itemBuilder(context, item, dense: false),
        );
      },
    );
  }
}
