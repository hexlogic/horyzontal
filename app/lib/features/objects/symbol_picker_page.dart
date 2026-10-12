import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:horyzontal_symbols/catalog.dart';

import '../../core/labels.dart';
import '../../core/settings.dart';
import 'symbol_icons.dart';
import 'symbols.dart';

final _catalog = SymbolCatalog.instance;

/// APP-6D symbol builder: search by name, browse the entity tree, set the
/// other SIDC fields, keep favourites. Returns the SIDC, or '' for "no
/// symbol".
class SymbolPickerPage extends ConsumerStatefulWidget {
  const SymbolPickerPage({super.key, this.initial});
  final String? initial;

  @override
  ConsumerState<SymbolPickerPage> createState() => _SymbolPickerPageState();
}

class _SymbolPickerPageState extends ConsumerState<SymbolPickerPage> {
  late Sidc _sidc = Sidc.tryParse(widget.initial ?? '') ?? Sidc();
  String _query = '';

  void _set(Sidc s) => setState(() => _sidc = s);

  Future<void> _save() async {
    final code = _sidc.toString();
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(
          symbolRecent: [code, ...s.symbolRecent.where((c) => c != code)].take(12).toList(),
        ));
    if (mounted) context.pop(code);
  }

  Future<void> _toggleFavorite() async {
    final code = _sidc.toString();
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(
          symbolFavorites: s.symbolFavorites.contains(code)
              ? s.symbolFavorites.where((c) => c != code).toList()
              : [...s.symbolFavorites, code],
        ));
  }

  Future<T?> _choose<T>(String title, List<T> values, String Function(T) label, {String Function(T)? subtitle}) =>
      showModalBottomSheet<T>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, scroll) => ListView(
            controller: scroll,
            children: [
              ListTile(title: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              for (final v in values)
                ListTile(
                  title: Text(label(v)),
                  subtitle: subtitle == null ? null : Text(subtitle(v)),
                  onTap: () => Navigator.pop(context, v),
                ),
            ],
          ),
        ),
      );

  Future<void> _browse() async {
    final picked = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => _EntityBrowser(setCode: _sidc.symbolSet, identity: _sidc.identity),
    ));
    if (picked != null) _set(_sidc.withEntity(picked).copyWith(modifier1: '00', modifier2: '00'));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final code = _sidc.toString();
    final favorite = s.symbolFavorites.contains(code);
    final set = _sidc.symbolSet;
    final entityPath = _catalog.path(set, _sidc.entity).map((e) => e.nameUk).join(' › ');
    final amplifiers = _catalog.amplifiers.where((a) =>
        a.code == '00' || (_isUnitSet(set) ? a.isEchelon : !a.isEchelon));
    final m1 = _catalog.modifiers(set, 1);
    final m2 = _catalog.modifiers(set, 2);
    final q = _query.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.symbol),
        actions: [
          IconButton(
            tooltip: l.favorite,
            icon: Icon(favorite ? Icons.star : Icons.star_border),
            onPressed: _toggleFavorite,
          ),
          TextButton(onPressed: () => context.pop(''), child: Text(l.symbolNone)),
          TextButton(onPressed: _save, child: Text(l.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(width: 96, height: 96, child: SymbolView(code, height: 96)),
                const SizedBox(width: 16),
                Expanded(child: Text(_describe(code), style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBar(
              hintText: l.symbolSearch,
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (q.isNotEmpty)
            for (final e in _catalog.search(q, limit: 40))
              ListTile(
                leading: SizedBox(
                  width: 44,
                  child: SymbolView(_sidc.withSymbolSet(e.setCode).withEntity(e.code).toString(), height: 36),
                ),
                title: Text(e.nameUk),
                subtitle: Text([
                  _catalog.symbolSet(e.setCode)?.nameUk ?? e.setCode,
                  ..._catalog.path(e.setCode, e.code).reversed.skip(1).map((p) => p.nameUk),
                ].join(' · ')),
                onTap: () => setState(() {
                  _sidc = _sidc.withSymbolSet(e.setCode).withEntity(e.code);
                  _query = '';
                }),
              )
          else ...[
            if (s.symbolFavorites.isNotEmpty) _Strip(title: l.favorites, codes: s.symbolFavorites, onPick: (c) => _set(Sidc.parse(c))),
            if (s.symbolRecent.isNotEmpty) _Strip(title: l.recent, codes: s.symbolRecent, onPick: (c) => _set(Sidc.parse(c))),
            ListTile(
              title: Text(l.sidcIdentity),
              subtitle: Text(_catalog.standardIdentity(_sidc.identity)?.nameUk ?? _sidc.identity),
              onTap: () async {
                final v = await _choose(l.sidcIdentity, _catalog.standardIdentities, (v) => v.nameUk);
                if (v != null) _set(_sidc.withIdentity(v.code));
              },
            ),
            ListTile(
              title: Text(l.sidcSet),
              subtitle: Text(_catalog.symbolSet(set)?.nameUk ?? set),
              onTap: () async {
                final v = await _choose(l.sidcSet, _catalog.sets, (v) => v.nameUk);
                if (v != null) _set(_sidc.withSymbolSet(v.code));
              },
            ),
            ListTile(
              title: Text(l.sidcEntity),
              subtitle: Text(entityPath.isEmpty ? l.sidcEntityNone : entityPath),
              trailing: const Icon(Icons.chevron_right),
              onTap: _browse,
            ),
            ListTile(
              title: Text(l.sidcStatus),
              subtitle: Text(_catalog.status(_sidc.status)?.nameUk ?? _sidc.status),
              onTap: () async {
                final v = await _choose(l.sidcStatus, _catalog.statuses, (v) => v.nameUk);
                if (v != null) _set(_sidc.withStatus(v.code));
              },
            ),
            ListTile(
              title: Text(l.sidcHq),
              subtitle: Text(_catalog.hqTfDummy(_sidc.hqTfDummy)?.nameUk ?? _sidc.hqTfDummy),
              onTap: () async {
                final v = await _choose(l.sidcHq, _catalog.hqTfDummies, (v) => v.nameUk);
                if (v != null) _set(_sidc.withHqTfDummy(v.code));
              },
            ),
            ListTile(
              title: Text(_isUnitSet(set) ? l.sidcEchelon : l.sidcMobility),
              subtitle: Text(_catalog.amplifier(_sidc.amplifier)?.nameUk ?? _sidc.amplifier),
              onTap: () async {
                final v = await _choose(_isUnitSet(set) ? l.sidcEchelon : l.sidcMobility, amplifiers.toList(),
                    (v) => v.nameUk, subtitle: (v) => v.groupUk);
                if (v != null) _set(_sidc.withAmplifier(v.code));
              },
            ),
            if (m1.length > 1)
              ListTile(
                title: Text(l.sidcModifier1),
                subtitle: Text(_catalog.modifier(set, 1, _sidc.modifier1)?.nameUk ?? _sidc.modifier1),
                onTap: () async {
                  final v = await _choose(l.sidcModifier1, m1, (v) => v.nameUk, subtitle: (v) => v.category ?? '');
                  if (v != null) _set(_sidc.withModifier1(v.code));
                },
              ),
            if (m2.length > 1)
              ListTile(
                title: Text(l.sidcModifier2),
                subtitle: Text(_catalog.modifier(set, 2, _sidc.modifier2)?.nameUk ?? _sidc.modifier2),
                onTap: () async {
                  final v = await _choose(l.sidcModifier2, m2, (v) => v.nameUk, subtitle: (v) => v.category ?? '');
                  if (v != null) _set(_sidc.withModifier2(v.code));
                },
              ),
            ListTile(
              dense: true,
              title: const Text('SIDC'),
              subtitle: SelectableText(code),
            ),
          ],
        ],
      ),
    );
  }

  static bool _isUnitSet(String set) => const {'10', '11'}.contains(set);

  static String _describe(String code) {
    try {
      return _catalog.describe(code);
    } on FormatException {
      return code;
    }
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.title, required this.codes, required this.onPick});
  final String title;
  final List<String> codes;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in codes)
                  InkWell(
                    onTap: () => onPick(c),
                    child: Padding(padding: const EdgeInsets.all(4), child: SymbolView(c, height: 56)),
                  ),
              ],
            ),
          ),
        ],
      );
}

/// Entity tree of one symbol set: entity › type › subtype. Only codes that
/// render as a point symbol are offered.
class _EntityBrowser extends StatefulWidget {
  const _EntityBrowser({required this.setCode, required this.identity});
  final String setCode, identity;

  @override
  State<_EntityBrowser> createState() => _EntityBrowserState();
}

class _EntityBrowserState extends State<_EntityBrowser> {
  final _stack = <SymbolEntity>[];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final parent = _stack.lastOrNull;
    final items = _catalog
        .children(widget.setCode, parent?.code)
        .where((e) => isPointSymbol(_preview(e.code)) || _catalog.children(widget.setCode, e.code).isNotEmpty)
        .toList();
    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_stack.removeLast);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(parent?.nameUk ?? _catalog.symbolSet(widget.setCode)?.nameUk ?? l.sidcEntity)),
        body: ListView(
          children: [
            if (parent != null && isPointSymbol(_preview(parent.code)))
              ListTile(
                leading: SizedBox(width: 48, child: SymbolView(_preview(parent.code), height: 40)),
                title: Text(l.sidcChooseThis(parent.nameUk)),
                onTap: () => Navigator.pop(context, parent.code),
              ),
            for (final e in items)
              ListTile(
                leading: SizedBox(width: 48, child: SymbolView(_preview(e.code), height: 40)),
                title: Text(e.nameUk),
                subtitle: e.remarks == null ? null : Text(e.nameEn, style: Theme.of(context).textTheme.bodySmall),
                trailing: _catalog.children(widget.setCode, e.code).isEmpty ? null : const Icon(Icons.chevron_right),
                onTap: () {
                  if (_catalog.children(widget.setCode, e.code).isEmpty) {
                    Navigator.pop(context, e.code);
                  } else {
                    setState(() => _stack.add(e));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _preview(String entity) =>
      (Sidc().withIdentity(widget.identity).withSymbolSet(widget.setCode).withEntity(entity)).toString();
}
