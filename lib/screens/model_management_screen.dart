import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../models/ai_model.dart';

class ModelManagementScreen extends StatefulWidget {
  const ModelManagementScreen({super.key});

  @override
  State<ModelManagementScreen> createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();
  List<AIModel> _allModels = [];
  List<AIModel> _filteredModels = [];
  List<AIModel> _selectedModels = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSelectedModels();
    _fetchAvailableModels();
    _searchController.addListener(_filterModels);
  }

  Future<void> _loadSelectedModels() async {
    try {
      final savedModels = await _storage.read(key: 'selected_models');
      if (savedModels != null) {
        final List<dynamic> jsonList = jsonDecode(savedModels);
        _selectedModels = jsonList.map((json) => AIModel.fromJson(json)).toList();
      }
    } catch (e) {
      // If there's an error loading saved models, use the default models from bloc
      final chatBloc = context.read<ChatBloc>();
      _selectedModels = List.from(chatBloc.availableModels);
    }
  }

  Future<void> _fetchAvailableModels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiKey = await _storage.read(key: 'openrouter_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _errorMessage = 'API key not found. Please set your API key in settings first.';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('https://openrouter.ai/api/v1/models');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = (data['data'] as List)
            .map((model) => AIModel(
                  id: model['id'] as String,
                  name: model['name'] as String,
                  description: model['description'] as String? ?? '',
                  provider: model['top_provider']?['name'] as String? ?? 'Unknown',
                ))
            .toList();

        setState(() {
          _allModels = models;
          _filteredModels = models;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch models: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching models: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredModels = _allModels;
        _isSearching = false;
      });
    } else {
      setState(() {
        _filteredModels = _allModels
            .where((model) =>
                model.name.toLowerCase().contains(query) ||
                model.id.toLowerCase().contains(query) ||
                model.provider.toLowerCase().contains(query))
            .toList();
        _isSearching = true;
      });
    }
  }

  bool _isSelected(AIModel model) {
    return _selectedModels.any((selected) => selected.id == model.id);
  }

  void _toggleModelSelection(AIModel model) {
    setState(() {
      if (_isSelected(model)) {
        _selectedModels.removeWhere((selected) => selected.id == model.id);
      } else {
        _selectedModels.add(model);
      }
    });
  }

  Future<void> _saveSelectedModels() async {
    try {
      final jsonModels = _selectedModels.map((model) => model.toJson()).toList();
      await _storage.write(key: 'selected_models', value: jsonEncode(jsonModels));

      // Update the bloc with the new model list
      final chatBloc = context.read<ChatBloc>();
      chatBloc.updateAvailableModels(_selectedModels);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Models saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving models: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterModels);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage AI Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAvailableModels,
            tooltip: 'Refresh Models',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search models...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterModels();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: _filteredModels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isSearching ? Icons.search_off : Icons.inbox,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSearching
                                ? 'No models found matching your search'
                                : 'No models available',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (!_isSearching)
                            const SizedBox(height: 8),
                          if (!_isSearching)
                            Text(
                              'Try refreshing the model list',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredModels.length,
                      itemBuilder: (context, index) {
                        final model = _filteredModels[index];
                        final isSelected = _isSelected(model);

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(model.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  model.id,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${model.provider} • ${model.description}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                _toggleModelSelection(model);
                              },
                            ),
                            onTap: () {
                              _toggleModelSelection(model);
                            },
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedModels.isEmpty
                    ? null
                    : _saveSelectedModels,
                child: const Text('Save Models'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}