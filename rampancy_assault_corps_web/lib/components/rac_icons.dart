import 'package:arcane_jaspr/arcane_jaspr.dart';

class RacIcons {
  const RacIcons._();

  static Component check({IconSize size = IconSize.md}) =>
      RacSvgIcon(size: size, paths: const <String>['M20 6 9 17 4 12']);

  static Component close({IconSize size = IconSize.md}) =>
      RacSvgIcon(size: size, paths: const <String>['M18 6 6 18', 'M6 6 18 18']);

  static Component trash({IconSize size = IconSize.md}) => RacSvgIcon(
    size: size,
    paths: const <String>[
      'M3 6H21',
      'M8 6V4H16V6',
      'M19 6 18 20H6L5 6',
      'M10 11V17',
      'M14 11V17',
    ],
  );
}

class RacSvgIcon extends StatelessComponent {
  final List<String> paths;
  final IconSize size;

  const RacSvgIcon({super.key, required this.paths, this.size = IconSize.md});

  @override
  Component build(BuildContext context) {
    String px = _pixelSize.toStringAsFixed(0);
    List<Component> pathChildren = <Component>[
      for (String path in paths)
        Component.element(
          tag: 'path',
          attributes: <String, String>{'d': path},
          children: const <Component>[],
        ),
    ];
    return Component.element(
      tag: 'svg',
      attributes: <String, String>{
        'width': px,
        'height': px,
        'viewBox': '0 0 24 24',
        'fill': 'none',
        'stroke': 'currentColor',
        'stroke-width': '2',
        'stroke-linecap': 'round',
        'stroke-linejoin': 'round',
        'aria-hidden': 'true',
      },
      children: pathChildren,
    );
  }

  double get _pixelSize => switch (size) {
    IconSize.xs => 12,
    IconSize.sm => 16,
    IconSize.md => 20,
    IconSize.lg => 24,
    IconSize.xl => 32,
    IconSize.xl2 => 48,
  };
}
