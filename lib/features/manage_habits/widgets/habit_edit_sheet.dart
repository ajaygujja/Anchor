import 'package:anchor/core/copy.dart';
import 'package:anchor/core/theme/theme.dart';
import 'package:flutter/material.dart';

/// The name and optional swatch chosen in [HabitEditSheet].
class HabitEditResult {
  const HabitEditResult({required this.name, this.color});

  final String name;
  final String? color;
}

/// Bottom sheet for creating or renaming a habit (spec §2.2D).
///
/// A swatch row is offered only when creating; renaming edits the name alone,
/// matching the repository surface. No confirmation dialogs (spec §2.6).
class HabitEditSheet extends StatefulWidget {
  const HabitEditSheet({this.initialName, super.key});

  /// Existing name when renaming; `null` when creating.
  final String? initialName;

  bool get _isEditing => initialName != null;

  /// Opens the sheet and resolves with the chosen values, or `null` if
  /// dismissed without a valid name.
  static Future<HabitEditResult?> show(
    BuildContext context, {
    String? initialName,
  }) {
    return showModalBottomSheet<HabitEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => HabitEditSheet(initialName: initialName),
    );
  }

  @override
  State<HabitEditSheet> createState() => _HabitEditSheetState();
}

class _HabitEditSheetState extends State<HabitEditSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );
  String? _color;
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    _valid = _controller.text.trim().isNotEmpty;
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(HabitEditResult(name: name, color: _color));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget._isEditing ? Copy.editHabit : Copy.addHabit;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: Copy.habitNameLabel),
            onChanged: (value) =>
                setState(() => _valid = value.trim().isNotEmpty),
            onSubmitted: (_) => _submit(),
          ),
          if (!widget._isEditing) ...[
            const SizedBox(height: 8),
            _SwatchRow(
              selected: _color,
              onSelected: (color) => setState(() => _color = color),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _valid ? _submit : null,
              child: const Text(Copy.save),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable row of the fixed habit swatches, plus a "no colour" option.
class _SwatchRow extends StatelessWidget {
  const _SwatchRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Swatch(
          color: scheme.surfaceContainerHighest,
          isSelected: selected == null,
          onTap: () => onSelected(null),
        ),
        for (final hex in AnchorTheme.habitSwatches)
          _Swatch(
            color: AnchorTheme.swatchColor(hex)!,
            isSelected: selected == hex,
            onTap: () => onSelected(hex),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? scheme.onSurface : scheme.outlineVariant,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
