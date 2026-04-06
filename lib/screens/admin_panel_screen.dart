import 'package:flutter/material.dart';
import '../models/tag_popularity.dart';
import '../services/api_service.dart';

class AdminPanelScreen extends StatefulWidget {
  final ApiService apiService;

  const AdminPanelScreen({super.key, required this.apiService});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<TagPopularity> _tags = [];
  List<TagPopularity> _filteredTags = [];
  bool _isLoading = false;
  bool _hasUnsyncedChanges = false;
  bool _isSyncing = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTags();
    _checkUnsyncedRules();
    _searchController.addListener(_filterTags);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTags() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredTags = _tags;
      } else {
        // Split query into words for cross-field matching.
        // e.g. "West cinematographer" matches records where "West" is in the
        // tag and "cinematographer" is in the category (or vice versa).
        final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        _filteredTags = _tags.where((tag) {
          final tagLower = tag.tag.toLowerCase();
          final categoryLower = (tag.category ?? '').toLowerCase();
          return words.every((word) =>
            tagLower.contains(word) || categoryLower.contains(word));
        }).toList();
      }
    });
  }

  Future<void> _loadTags() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tags = await widget.apiService.getAll();
      setState(() {
        _tags = tags;
        _filteredTags = tags;
        _isLoading = false;
      });
      _filterTags();
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load tags: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUnsyncedRules() async {
    try {
      final hasUnsynced = await widget.apiService.hasUnsyncedRules();
      if (mounted) {
        setState(() => _hasUnsyncedChanges = hasUnsynced);
      }
    } catch (_) {
      // Silently fail — button stays in current state
    }
  }

  Future<void> _sync() async {
    setState(() => _isSyncing = true);

    try {
      final result = await widget.apiService.applyRules();
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _hasUnsyncedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync complete: ${result.rulesProcessed} rules processed, '
              '${result.totalImagesUpdated} images updated',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadTags();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<TagPopularity>(
      context: context,
      builder: (context) => _TagDialog(
        title: 'Add Tag',
        apiService: widget.apiService,
      ),
    );

    if (result != null) {
      _loadTags();
      setState(() => _hasUnsyncedChanges = true);
    }
  }

  Future<void> _showEditDialog(TagPopularity tag) async {
    final result = await showDialog<TagPopularity>(
      context: context,
      builder: (context) => _TagDialog(
        title: 'Edit Tag',
        apiService: widget.apiService,
        existingTag: tag,
      ),
    );

    if (result != null) {
      _loadTags();
      setState(() => _hasUnsyncedChanges = true);
    }
  }

  Future<void> _deleteTag(TagPopularity tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text('Are you sure you want to delete "${tag.tag}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.delete(tag.id);
        _loadTags();
        setState(() => _hasUnsyncedChanges = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${tag.tag}"')),
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'assets/shotdeck_website_logo_r.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            const Text(
              'Tag Popularity Admin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _hasUnsyncedChanges ? _sync : null,
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasUnsyncedChanges ? Colors.orange : null,
                      foregroundColor: _hasUnsyncedChanges ? Colors.white : null,
                    ),
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadTags,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tags...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_filteredTags.length} of ${_tags.length} tags',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Tag'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading tags',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTags,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No tags yet'
                  : 'No tags match your search',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (_searchController.text.isEmpty)
              const Text('Click the + button to add one'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredTags.length,
      itemBuilder: (context, index) {
        final tag = _filteredTags[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(
              tag.tag,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Row(
              children: [
                if (tag.category != null && tag.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple[800],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tag.percentage >= 0
                        ? Colors.green[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${tag.percentage}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: tag.percentage >= 0
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tag.isActive
                        ? Colors.blue[100]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: tag.isActive
                          ? Colors.blue[800]
                          : Colors.grey[700],
                    ),
                  ),
                ),
                if (tag.baseWeightedScore != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Base: ${tag.baseWeightedScore!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
                if (tag.weightedScore != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Weighted: ${tag.weightedScore!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => _showEditDialog(tag),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  color: Colors.red,
                  onPressed: () => _deleteTag(tag),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TagDialog extends StatefulWidget {
  final String title;
  final ApiService apiService;
  final TagPopularity? existingTag;

  const _TagDialog({
    required this.title,
    required this.apiService,
    this.existingTag,
  });

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tagSearchController = TextEditingController();
  final _percentageController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  List<TagSearchResult> _searchResults = [];
  String? _selectedTag;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.existingTag != null) {
      _tagSearchController.text = widget.existingTag!.tag;
      _selectedTag = widget.existingTag!.tag;
      _selectedCategory = widget.existingTag!.category;
      _percentageController.text = widget.existingTag!.percentage.toString();
      _isActive = widget.existingTag!.isActive;
    }
  }

  @override
  void dispose() {
    _tagSearchController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _searchTags(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await widget.apiService.searchTags(query.trim());
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = widget.existingTag != null;
    if (!isEditing && (_selectedTag == null || _selectedTag!.isEmpty)) {
      setState(() {
        _errorMessage = 'Please select a tag from the dropdown';
      });
      return;
    }
    final tagToSave = isEditing ? _tagSearchController.text.trim() : _selectedTag!;
    final categoryToSave = _selectedCategory;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      TagPopularity result;
      if (widget.existingTag != null) {
        result = await widget.apiService.update(
          widget.existingTag!.id,
          UpdateTagPopularityRequest(
            tag: tagToSave,
            percentage: int.parse(_percentageController.text.trim()),
            isActive: _isActive,
            category: categoryToSave,
          ),
        );
      } else {
        result = await widget.apiService.create(
          CreateTagPopularityRequest(
            tag: tagToSave,
            percentage: int.parse(_percentageController.text.trim()),
            isActive: _isActive,
            category: categoryToSave,
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTag != null;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _tagSearchController,
                decoration: InputDecoration(
                  labelText: 'Tag',
                  hintText: isEditing
                      ? 'Edit tag name'
                      : 'Search for a tag...',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                readOnly: isEditing,
                onChanged: isEditing
                    ? null
                    : (value) {
                        _selectedTag = null;
                        _searchTags(value);
                      },
                validator: (value) {
                  if (!isEditing && (_selectedTag == null || _selectedTag!.isEmpty)) {
                    return 'Please search and select a tag from the dropdown';
                  }
                  return null;
                },
                autofocus: !isEditing,
              ),
              if (_searchResults.isNotEmpty && _selectedTag == null && !isEditing)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade600),
                    borderRadius: BorderRadius.circular(4),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text('${result.origin}: ${result.tag}'),
                        onTap: () {
                          setState(() {
                            _selectedTag = result.tag;
                            _selectedCategory = result.origin;
                            _tagSearchController.text = result.tag;
                            _searchResults = [];
                          });
                        },
                      );
                    },
                  ),
                ),
              if (_selectedTag != null && !isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[400], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Selected: ${_selectedCategory != null ? '$_selectedCategory: ' : ''}$_selectedTag',
                          style: TextStyle(
                            color: Colors.green[400],
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTag = null;
                            _selectedCategory = null;
                            _tagSearchController.clear();
                            _searchResults = [];
                          });
                        },
                        child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: TextEditingController(text: _selectedCategory ?? widget.existingTag?.category ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  hintText: 'Auto-filled from tag selection',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _percentageController,
                decoration: const InputDecoration(
                  labelText: 'Percentage',
                  hintText: 'Enter percentage (e.g. -20, 50)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a percentage';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
                autofocus: isEditing,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Active'),
                subtitle: const Text(
                  'If enabled, this tag popularity adjustment is active',
                ),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingTag != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
