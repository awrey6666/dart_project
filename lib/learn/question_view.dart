import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'learn_models.dart';

const _okColor = Color(0xFF2E7D32);
const _badColor = Color(0xFFC62828);

/// Ցուցադրում է հարցը՝ ըստ տիպի։ [onChanged]-ը ստանում է ընթացիկ պատասխանը
/// (կամ null, եթե դեռ պատրաստ չէ ստուգման)։
class QuestionView extends StatefulWidget {
  const QuestionView({
    super.key,
    required this.question,
    required this.onChanged,
    required this.onSubmit,
    required this.revealed,
  });

  final Question question;
  final ValueChanged<Object?> onChanged;
  final VoidCallback onSubmit;

  /// true՝ ստուգումից հետո (մուտքը կասեցված է, ճիշտ/սխալը ընդգծված է)։
  final bool revealed;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  int? _selected;
  final _text = TextEditingController();
  late List<int> _order;
  late List<int> _rightOrder;
  late List<int?> _choices;

  Question get q => widget.question;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _order = List<int>.generate(q.options.length, (i) => i);
    if (q.type == QuestionType.ordering && _order.length > 1) {
      do {
        _order.shuffle(random);
      } while (_isSorted(_order));
    }
    _rightOrder = List<int>.generate(q.rights.length, (i) => i)..shuffle(random);
    _choices = List<int?>.filled(q.options.length, null);
    if (q.type == QuestionType.ordering) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(List<int>.of(_order));
      });
    }
  }

  bool _isSorted(List<int> list) {
    for (var i = 0; i < list.length; i++) {
      if (list[i] != i) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = q.prompt.split('\n');
    final head = lines.first;
    final body = lines.length > 1 ? lines.skip(1).join('\n') : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(head, style: Theme.of(context).textTheme.titleMedium),
        if (body != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              body,
              style: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _input(context),
      ],
    );
  }

  Widget _input(BuildContext context) {
    switch (q.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _choiceList();
      case QuestionType.fillBlank:
      case QuestionType.numeric:
      case QuestionType.code:
        return _textField(multiline: false);
      case QuestionType.open:
        return _textField(multiline: true);
      case QuestionType.ordering:
        return _orderingList();
      case QuestionType.matching:
        return _matchingList();
    }
  }

  // ---------------- Ընտրություն ----------------

  Widget _choiceList() {
    return Column(
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: q.options[i],
              selected: _selected == i,
              state: !widget.revealed
                  ? _TileState.neutral
                  : i == q.answerIndex
                  ? _TileState.correct
                  : (_selected == i ? _TileState.wrong : _TileState.neutral),
              onTap: widget.revealed
                  ? null
                  : () {
                      setState(() => _selected = i);
                      widget.onChanged(i);
                    },
            ),
          ),
      ],
    );
  }

  // ---------------- Տեքստ / թիվ / կոդ ----------------

  Widget _textField({required bool multiline}) {
    final numeric = q.type == QuestionType.numeric;
    return TextField(
      controller: _text,
      enabled: !widget.revealed,
      autofocus: !multiline,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 6 : 1,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : (multiline ? TextInputType.multiline : TextInputType.text),
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-\.,]'))]
          : null,
      style: q.type == QuestionType.code
          ? const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'])
          : null,
      decoration: InputDecoration(
        labelText: switch (q.type) {
          QuestionType.numeric => 'Պատասխան (թիվ)',
          QuestionType.code => 'Արդյունք / կոդ',
          QuestionType.open => 'Ձեր բացատրությունը',
          _ => 'Պատասխան',
        },
      ),
      onChanged: (value) => widget.onChanged(value.trim().isEmpty ? null : value),
      onSubmitted: multiline ? null : (_) => widget.onSubmit(),
    );
  }

  // ---------------- Հերթականություն ----------------

  Widget _orderingList() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Քաշեք տարրերը ճիշտ հերթականությամբ դասավորելու համար։',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: !widget.revealed,
          onReorder: (oldIndex, newIndex) {
            if (widget.revealed) return;
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
            widget.onChanged(List<int>.of(_order));
          },
          children: [
            for (var position = 0; position < _order.length; position++)
              Padding(
                key: ValueKey('order-${_order[position]}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: _OptionTile(
                  label: '${position + 1}. ${q.options[_order[position]]}',
                  selected: false,
                  state: !widget.revealed
                      ? _TileState.neutral
                      : (_order[position] == position ? _TileState.correct : _TileState.wrong),
                  onTap: null,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------- Համապատասխանություն ----------------

  Widget _matchingList() {
    return Column(
      children: [
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _OptionTile(
                    label: q.options[i],
                    selected: false,
                    state: !widget.revealed
                        ? _TileState.neutral
                        : (_choices[i] == i ? _TileState.correct : _TileState.wrong),
                    onTap: null,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  flex: 5,
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _choices[i],
                    hint: const Text('Ընտրեք'),
                    items: [
                      for (final r in _rightOrder)
                        DropdownMenuItem<int>(
                          value: r,
                          child: Text(q.rights[r], overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: widget.revealed
                        ? null
                        : (value) {
                            setState(() => _choices[i] = value);
                            widget.onChanged(
                              _choices.contains(null)
                                  ? null
                                  : [for (final c in _choices) c!],
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _TileState { neutral, correct, wrong }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.state,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final _TileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color border = scheme.outlineVariant;
    Color fill = scheme.surfaceContainerLow;
    IconData? icon;
    switch (state) {
      case _TileState.correct:
        border = _okColor;
        fill = _okColor.withValues(alpha: 0.15);
        icon = Icons.check_circle;
      case _TileState.wrong:
        border = _badColor;
        fill = _badColor.withValues(alpha: 0.15);
        icon = Icons.cancel;
      case _TileState.neutral:
        if (selected) {
          border = scheme.primary;
          fill = scheme.primaryContainer;
        }
    }
    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: selected || icon != null ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              if (icon != null) Icon(icon, color: border),
            ],
          ),
        ),
      ),
    );
  }
}
