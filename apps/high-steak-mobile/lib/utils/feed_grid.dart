import 'package:flutter/widgets.dart';

/// Column count for post feed grids (feed, profile, bookmarks, explore place posts).
int feedGridCrossAxisCount(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  return 2;
}

double feedGridSpacing(BuildContext context) => 12;

/// Width / height for grid tiles. Lower values yield taller cells.
double feedGridChildAspectRatio(
  BuildContext context, {
  bool showAuthorHeader = true,
}) {
  final columns = feedGridCrossAxisCount(context);
  if (columns <= 2) {
    return showAuthorHeader ? 0.56 : 0.62;
  }
  return showAuthorHeader ? 0.66 : 0.72;
}
