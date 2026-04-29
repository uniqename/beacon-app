import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class EssentialItemsScreen extends StatefulWidget {
  final String userId;

  const EssentialItemsScreen({super.key, required this.userId});

  @override
  State<EssentialItemsScreen> createState() => _EssentialItemsScreenState();
}

class _EssentialItemsScreenState extends State<EssentialItemsScreen> {
  final SafetyPlanService _service = SafetyPlanService();
  SafetyPlan? _safetyPlan;
  List<String> _allItems = [];
  Set<String> _checkedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSafetyPlan();
  }

  Future<void> _loadSafetyPlan() async {
    setState(() => _isLoading = true);

    try {
      var plan = await _service.getSafetyPlan(widget.userId);
      plan ??= await _service.createSafetyPlan(widget.userId);

      // Get default items from service
      final defaultItems = _service.getDefaultEssentialItems();

      // Combine default items with any custom items from the plan
      final customItems = plan.essentialItems.where((item) => !defaultItems.contains(item)).toList();

      setState(() {
        _safetyPlan = plan;
        _allItems = [...defaultItems, ...customItems];
        _checkedItems = Set.from(plan!.checkedItems);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  Future<void> _saveCheckedItems() async {
    if (_safetyPlan == null) return;

    final updatedPlan = _safetyPlan!.copyWith(
      essentialItems: _allItems,
      checkedItems: _checkedItems.toList(),
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
  }

  Future<void> _toggleItem(String item, bool checked) async {
    setState(() {
      if (checked) {
        _checkedItems.add(item);
      } else {
        _checkedItems.remove(item);
      }
    });

    await _saveCheckedItems();
  }

  Future<void> _addCustomItem(String item) async {
    if (_allItems.contains(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item already exists')),
      );
      return;
    }

    setState(() {
      _allItems.add(item);
      _checkedItems.add(item);
    });

    await _saveCheckedItems();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item added and checked')),
    );
  }

  Future<void> _removeCustomItem(String item) async {
    // Only allow removing custom items (not default ones)
    final defaultItems = _service.getDefaultEssentialItems();
    if (defaultItems.contains(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot remove default items')),
      );
      return;
    }

    setState(() {
      _allItems.remove(item);
      _checkedItems.remove(item);
    });

    await _saveCheckedItems();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Custom item removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Essential Items'),
          backgroundColor: Colors.green[600],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final checkedCount = _checkedItems.length;
    final totalCount = _allItems.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Essential Items'),
        backgroundColor: Colors.green[600],
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddItemDialog,
            tooltip: 'Add Custom Item',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items Packed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$checkedCount of $totalCount',
                      style: TextStyle(fontSize: 16, color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                  minHeight: 8,
                ),
                SizedBox(height: 8),
                Text(
                  'Keep these items in a safe, accessible place for quick exit',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          // Items list
          Expanded(
            child: _allItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2, size: 80, color: Colors.grey[400]),
                        SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _allItems.length,
                    itemBuilder: (context, index) {
                      final item = _allItems[index];
                      final isChecked = _checkedItems.contains(item);
                      final isCustom = !_service.getDefaultEssentialItems().contains(item);

                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: CheckboxListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              decoration: isChecked ? TextDecoration.lineThrough : null,
                              color: isChecked ? Colors.grey[600] : null,
                            ),
                          ),
                          subtitle: isCustom ? Text('Custom item', style: TextStyle(fontSize: 12, color: Colors.blue)) : null,
                          value: isChecked,
                          onChanged: (value) => _toggleItem(item, value ?? false),
                          secondary: isCustom
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDeleteCustomItem(item),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),

          // Quick actions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _checkAll,
                    icon: Icon(Icons.check_circle_outline),
                    label: Text('Check All'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _uncheckAll,
                    icon: Icon(Icons.cancel_outlined),
                    label: Text('Uncheck All'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _checkAll() {
    setState(() {
      _checkedItems = Set.from(_allItems);
    });
    _saveCheckedItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All items checked')),
    );
  }

  void _uncheckAll() {
    setState(() {
      _checkedItems.clear();
    });
    _saveCheckedItems();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All items unchecked')),
    );
  }

  void _confirmDeleteCustomItem(String item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Custom Item?'),
        content: Text('Remove "$item" from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeCustomItem(item);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom Item'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Laptop, Journal, Jewelry',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an item name';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _addCustomItem(controller.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            child: Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}
