import 'package:flutter/material.dart';

import '../models/idea.dart';
import '../services/idea_database.dart';
import 'idea_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _database = IdeaDatabase.instance;
  late Future<List<Idea>> _ideasFuture;

  @override
  void initState() {
    super.initState();
    _reloadIdeas();
  }

  void _reloadIdeas() {
    setState(() {
      _ideasFuture = _database.getAllIdeas();
    });
  }

  Future<void> _openIdeaForm({Idea? idea}) async {
    final result = await Navigator.of(context).push<Idea>(
      MaterialPageRoute(builder: (_) => IdeaFormScreen(idea: idea)),
    );

    if (result == null) return;

    if (idea == null) {
      await _database.insertIdea(result);
    } else {
      await _database.updateIdea(result);
    }
    _reloadIdeas();
  }

  Future<bool> _confirmDelete(Idea idea) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아이디어 삭제'),
        content: Text('"${idea.title}"을(를) 삭제할까요?\n삭제하면 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _deleteIdea(Idea idea) async {
    await _database.deleteIdea(idea.id!);
    _reloadIdeas();
  }

  Future<void> _toggleFavorite(Idea idea) async {
    await _database.toggleFavorite(idea.id!, !idea.isFavorite);
    _reloadIdeas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아이디어 저장소')),
      body: FutureBuilder<List<Idea>>(
        future: _ideasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final ideas = snapshot.data ?? [];

          if (ideas.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: ideas.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final idea = ideas[index];
              return Dismissible(
                key: ValueKey(idea.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Theme.of(context).colorScheme.errorContainer,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(idea),
                onDismissed: (_) => _deleteIdea(idea),
                child: ListTile(
                  title: Text(
                    idea.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    idea.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      idea.isFavorite ? Icons.star : Icons.star_border,
                      color: idea.isFavorite ? Colors.amber : null,
                    ),
                    tooltip: '즐겨찾기',
                    onPressed: () => _toggleFavorite(idea),
                  ),
                  onTap: () => _openIdeaForm(idea: idea),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openIdeaForm(),
        tooltip: '새 아이디어 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 저장된 아이디어가 없어요.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 아래 + 버튼을 눌러 첫 아이디어를 기록해보세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
