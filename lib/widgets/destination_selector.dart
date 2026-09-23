import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ai_destination.dart';
import '../services/destination_store.dart';

/// Destination selector shown in the footer.
///
/// The application does not send prompts directly to any AI — tapping a
/// destination only opens the user's chosen AI web app so they can paste the
/// generated prompt there.
///
/// Favorites are persisted between launches, sorted to the top of the list
/// (alphabetical inside each group).
class DestinationSelector extends StatefulWidget {
  const DestinationSelector({super.key, this.destinationStore});

  /// Optional injected persistence store; defaults to JSON file storage.
  final DestinationStore? destinationStore;

  @override
  State<DestinationSelector> createState() => _DestinationSelectorState();
}

class _DestinationSelectorState extends State<DestinationSelector> {
  late final DestinationStore _store;

  /// Favorite destination IDs loaded from disk.
  Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _store = widget.destinationStore ?? DestinationStore();
  }

  Future<void> _openMenu() async {
    // Refresh persisted favorites before opening.
    _favoriteIds = await _store.loadFavoriteIds();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _DestinationDialog(
        destinations: _sortedDestinations(),
        favoriteIds: _favoriteIds,
        onToggleFavorite: (id, favorite) => _toggleFavorite(id, favorite),
      ),
    );
  }

  /// Toggles a favorite, persists it, and updates every open dialog copy.
  void _toggleFavorite(String id, bool favorite) {
    final next = Set<String>.of(_favoriteIds);
    if (favorite) {
      next.add(id);
    } else {
      next.remove(id);
    }
    _favoriteIds = next;
    _store.saveFavoriteIds(next);
    // Force the dialog copy to reflect the new sort/state.
    if (mounted) setState(() {});
  }

  /// Favorites first, alphabetical within each group.
  List<AiDestination> _sortedDestinations() {
    final favorites = <AiDestination>[];
    final others = <AiDestination>[];
    for (final d in defaultDestinations) {
      if (_favoriteIds.contains(d.id)) {
        favorites.add(d);
      } else {
        others.add(d);
      }
    }
    final byName = (AiDestination a, AiDestination b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());
    favorites.sort(byName);
    others.sort(byName);
    return [...favorites, ...others];
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _openMenu,
      icon: const Icon(Icons.smart_toy_outlined, size: 16),
      label: const Text('Destination'),
    );
  }
}

/// Modal panel listing destinations with inline favorite toggles.
class _DestinationDialog extends StatefulWidget {
  const _DestinationDialog({
    required this.destinations,
    required this.favoriteIds,
    required this.onToggleFavorite,
  });

  final List<AiDestination> destinations;
  final Set<String> favoriteIds;
  final void Function(String id, bool favorite) onToggleFavorite;

  @override
  State<_DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<_DestinationDialog> {
  late Set<String> _favoriteIds;
  late List<AiDestination> _destinations;

  @override
  void initState() {
    super.initState();
    _favoriteIds = Set<String>.of(widget.favoriteIds);
    _destinations = List<AiDestination>.of(widget.destinations);
  }

  void _toggle(String id) {
    final favorite = !_favoriteIds.contains(id);
    setState(() {
      if (favorite) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      // Re-sort so favorites appear at the top immediately.
      final favorites = <AiDestination>[];
      final others = <AiDestination>[];
      for (final d in _destinations) {
        if (_favoriteIds.contains(d.id)) {
          favorites.add(d);
        } else {
          others.add(d);
        }
      }
      final byName = (AiDestination a, AiDestination b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase());
      favorites.sort(byName);
      others.sort(byName);
      _destinations = [...favorites, ...others];
    });
    widget.onToggleFavorite(id, favorite);
  }

  void _launch(AiDestination destination) {
    Navigator.pop(context);
    launchUrl(Uri.parse(destination.url),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Destination'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      // A scrollable `ListView` cannot be measured inside the AlertDialog's
      // IntrinsicWidth pass, which made the dialog open with an empty body.
      // A fixed-width `SingleChildScrollView` + `Column` is layout-safe and
      // renders the full destination list on every platform (iOS included).
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final destination in _destinations)
                ListTile(
                  dense: true,
                  leading: IconButton(
                    icon: Icon(
                      _favoriteIds.contains(destination.id)
                          ? Icons.star
                          : Icons.star_border,
                      size: 20,
                      color: _favoriteIds.contains(destination.id)
                          ? Colors.amber
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: _favoriteIds.contains(destination.id)
                        ? 'Remove favorite'
                        : 'Mark as favorite',
                    onPressed: () => _toggle(destination.id),
                  ),
                  title: Text(destination.name),
                  onTap: () => _launch(destination),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}