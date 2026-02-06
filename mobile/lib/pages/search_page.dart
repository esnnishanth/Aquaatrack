import 'package:flutter/material.dart';
import '../algorithms/fuzzy.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _data = [
    'Pipe A 4 inch',
    'Pipe B 6 inch',
    'Valve 2 inch',
    'Pump Model X',
    'Elbow 90°',
    'Coupling',
  ];
  List<String> _results = [];

  void _search(String term) {
    if (term.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final res = fuzzySearch(term, _data, maxResults: 10);
    setState(() => _results = res);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search inventory...'),
            onChanged: _search,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('No results'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, i) => ListTile(title: Text(_results[i])),
                  ),
          ),
        ],
      ),
    );
  }
}
