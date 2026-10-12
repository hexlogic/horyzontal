import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Window widths by Material 3 size classes, by window, not by device: an
/// iPad in narrow Split View gets the phone layout. From [railWidth] the tabs
/// move to a navigation rail; from [wideLayoutWidth] the object card sits
/// beside the map and pages stop growing.
const railWidth = 600.0;
const wideLayoutWidth = 840.0;

/// Pages of text and forms stop growing at this width on a wide window.
const contentMaxWidth = 720.0;

/// Width of the side panel with an object card next to the map.
const sidePanelWidth = 400.0;

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wideLayoutWidth;

bool useRail(BuildContext context) => MediaQuery.sizeOf(context).width >= railWidth;

/// Phones stay in portrait; tablets (shortest side of 600 dp and more)
/// turn freely. Android has no way to say this in the manifest.
Future<void> lockPhoneOrientation() async {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return;
  final v = views.first;
  final shortest = v.physicalSize.shortestSide / v.devicePixelRatio;
  await SystemChrome.setPreferredOrientations(
    shortest < 600 ? const [DeviceOrientation.portraitUp] : const [],
  );
}

/// Centres [child] and limits its width on a wide window.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = contentMaxWidth});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
  );
}
