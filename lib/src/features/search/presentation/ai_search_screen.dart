import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../shared/widgets/skeleton.dart';
import '../../categories/domain/category.dart';
import '../../categories/presentation/category_controller.dart';
import '../../home/presentation/home_screen.dart';
import '../../products/presentation/product_card.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/products_controller.dart';
import 'recent_searches_controller.dart';
import 'search_controller.dart';

const _examples = [
  'Cotton kurtis under ₹300',
  'Packaging covers & bags',
  'Hangers for display',
  'Silk sarees',
  'Tags and labels',
];

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  final SpeechToText _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechReady = await _speech.initialize(
        onStatus: (s) {
          if (mounted) setState(() => _listening = s == SpeechToText.listeningStatus);
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      _speechReady = false;
    }
    if (mounted) setState(() {});
  }

  /// Starts/stops voice capture; speech is transcribed into the field live and
  /// the search runs on the final result.
  Future<void> _toggleListen() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_listening) {
      await _speech.stop();
      return;
    }
    if (!_speechReady) await _initSpeech();
    if (!_speechReady) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Voice search isn’t available — check microphone permission.')),
        );
      return;
    }
    _focus.unfocus();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _controller.text = result.recognizedWords);
    if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
      _runQuery(result.recognizedWords.trim());
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Single entry point for running a query: mirrors it into the field,
  /// dismisses the keyboard, remembers it, and kicks off the search.
  void _runQuery(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    if (_controller.text != trimmed) _controller.text = trimmed;
    _focus.unfocus();
    ref.read(recentSearchesProvider.notifier).add(trimmed);
    ref.read(searchControllerProvider.notifier).run(trimmed);
  }

  /// Picking a matched category filters the Home tab by it and returns there.
  void _pickCategory(Category c) {
    ref.read(productSearchProvider.notifier).state = '';
    ref.read(selectedCategoryProvider.notifier).state = c;
    ref.read(homeTabProvider.notifier).state = 0;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _runQuery,
          decoration: InputDecoration(
            hintText: 'Search anything for your store…',
            prefixIcon: const Icon(Icons.auto_awesome, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                ref.read(searchControllerProvider.notifier).clear();
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _listening ? 'Stop listening' : 'Voice search',
            icon: Icon(
              _listening ? Icons.mic : Icons.mic_none,
              color: _listening ? theme.colorScheme.error : null,
            ),
            onPressed: _toggleListen,
          ),
        ],
      ),
      body: state.when(
        loading: () => const ProductGridSkeleton(),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(e.toString()))),
        data: (result) {
          if (result == null) return _Suggestions(onTap: _runQuery);
          final hasCategories = result.categories.isNotEmpty;
          if (result.items.isEmpty && !hasCategories) {
            return _Empty(reply: result.reply);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(result.aiPowered ? Icons.auto_awesome : Icons.search,
                          size: 16, color: theme.hintColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(result.reply, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasCategories)
                SliverToBoxAdapter(
                  child: _CategoryChips(categories: result.categories, onPick: _pickCategory),
                ),
              if (result.items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('No products matched — try a category above.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                  ),
                )
              else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final p = result.items[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                        ),
                      );
                    },
                    childCount: result.items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Matched-category quick filters shown above search results.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.categories, required this.onPick});
  final List<Category> categories;
  final void Function(Category) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Categories', style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map((c) => ActionChip(
                      avatar: const Icon(Icons.category_outlined, size: 16),
                      label: Text(c.name),
                      onPressed: () => onPick(c),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Suggestions extends ConsumerWidget {
  const _Suggestions({required this.onTap});
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recents = ref.watch(recentSearchesProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            children: [
              Icon(Icons.history, size: 18, color: theme.hintColor),
              const SizedBox(width: 6),
              Text('Recent', style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor)),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(recentSearchesProvider.notifier).clear(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final q in recents)
            _RecentTile(
              query: q,
              onTap: () => onTap(q),
              onRemove: () => ref.read(recentSearchesProvider.notifier).remove(q),
            ),
          const SizedBox(height: 20),
        ],
        Text('Try asking for…', style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _examples
              .map((e) => ActionChip(
                    label: Text(e),
                    onPressed: () => onTap(e),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// A single recent-search row: tap the text to re-run it, or the ✕ to forget.
class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.query, required this.onTap, required this.onRemove});
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.north_west, size: 16, color: theme.hintColor),
            const SizedBox(width: 12),
            Expanded(child: Text(query, style: theme.textTheme.bodyLarge)),
            InkResponse(
              onTap: onRemove,
              radius: 22,
              child: Semantics(
                button: true,
                label: 'Remove $query from recent searches',
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: theme.hintColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.reply});
  final String reply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No products matched', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(reply, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ],
        ),
      ),
    );
  }
}
