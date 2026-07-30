import 'package:flutter/material.dart';

import '../models/idea.dart';
import '../services/idea_database.dart';
import 'idea_form_screen.dart';

const Color _kPrimaryBlue = Color(0xFF0080F7);

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _database = IdeaDatabase.instance;
  final _searchController = TextEditingController();
  late Future<List<Idea>> _ideasFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _ideasFuture = _database.getAllIdeas();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Idea> _filterIdeas(List<Idea> ideas) {
    final query = _query.toLowerCase();
    return ideas
        .where((idea) =>
            idea.title.toLowerCase().contains(query) ||
            idea.content.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _openIdea(Idea idea) async {
    final result = await Navigator.of(context).push<Idea>(
      MaterialPageRoute(builder: (_) => IdeaFormScreen(idea: idea)),
    );

    if (result == null) return;
    await _database.updateIdea(result);
    setState(() {
      _ideasFuture = _database.getAllIdeas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '아이디어 검색',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: _kPrimaryBlue, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Idea>>(
              future: _ideasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_query.isEmpty) {
                  return const Center(
                    child: Text('찾고 싶은 아이디어를 검색해보세요 🔍'),
                  );
                }

                final ideas = snapshot.data ?? [];
                final filtered = _filterIdeas(ideas);

                if (filtered.isEmpty) {
                  return const Center(child: Text('찾는 아이디어가 없어요'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final idea = filtered[index];
                    return ListTile(
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
                      onTap: () => _openIdea(idea),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
