import 'package:flutter/material.dart';

/// Root navigator — full-screen overlays (photo lightbox) render above the shell.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Shell navigator — feed, profile, and other tab routes.
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

/// Context tied to the root navigator, when the widget tree has finished mounting.
BuildContext? get rootNavigatorContext => rootNavigatorKey.currentContext;
