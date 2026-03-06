import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/debt.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum SortType { original, alpha, amountDesc, amountAsc }

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Debt> _debts = [];
  bool _isLoading = true;
  SortType _currentSort = SortType.alpha;
  String _searchQuery = '';
  bool _isSearching = false;
  bool _viewDeleted = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    try {
      final debts = await SupabaseService.getDebts();
      setState(() {
        _debts = debts; // Загружаем все записи без фильтрации
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading debts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showDemoData() {
    setState(() {
      _debts = [
        Debt(
          id: '1',
          userId: '1',
          personName: 'дядя юра китай база',
          phoneNumber: '0554501130',
          amount: 7505,
          date: DateTime.now(),
          type: DebtType.owed,
          description: 'Из таблицы',
        ),
        Debt(
          id: '2',
          userId: '1',
          personName: 'анара газина',
          phoneNumber: '0709160863',
          amount: 2557,
          date: DateTime.now(),
          type: DebtType.owed,
        ),
      ];
    });
  }

  void _deleteAllDebts() {
    setState(() {
      _debts.clear();
    });
    // SupabaseService.deleteAll(DebtType.owed)
  }

  double get _totalOwed => _debts.where((d) => !d.isPaid).fold(0, (sum, item) => sum + item.amount);

  List<Debt> get _sortedDebts {
    List<Debt> filtered = _debts.where((d) => d.isDeleted == _viewDeleted).toList();
    
    // Сначала фильтруем по поиску
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) => 
        d.personName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        d.phoneNumber.contains(_searchQuery)
      ).toList();
    }

    if (_currentSort == SortType.alpha) {
      filtered.sort((a, b) => a.personName.trim().toLowerCase().compareTo(b.personName.trim().toLowerCase()));
    } else if (_currentSort == SortType.amountDesc) {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (_currentSort == SortType.amountAsc) {
      filtered.sort((a, b) => a.amount.compareTo(b.amount));
    } else {
      // original (как в списке) - ничего не делаем, так как список уже пришел в нужном порядке
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildSortFilters(),
            const SizedBox(height: 8),
            Expanded(
              child: _buildDebtList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDebtDialog(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_isSearching)
                const Text('Aikol', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1)),
              if (_isSearching)
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 20),
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppTheme.textDim),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search, color: AppTheme.textDim),
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        } else {
                          _isSearching = true;
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(_viewDeleted ? Icons.delete_outline : Icons.delete_sweep_outlined, 
                        color: _viewDeleted ? AppTheme.primary : AppTheme.textDim),
                    onPressed: () => setState(() => _viewDeleted = !_viewDeleted),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: AppTheme.textDim),
                    onPressed: () => SupabaseService.signOut(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.8), AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Общая сумма долгов', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat.currency(locale: 'ru_RU', symbol: 'с').format(_totalOwed)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSortFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildSortButton('Алфавит', SortType.alpha),
          const SizedBox(width: 8),
          _buildSortButton('По списку', SortType.original),
          const SizedBox(width: 8),
          _buildSortButton('Большой долг', SortType.amountDesc),
          const SizedBox(width: 8),
          _buildSortButton('Меньший долг', SortType.amountAsc),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, SortType type) {
    bool isSelected = _currentSort == type;
    return GestureDetector(
      onTap: () => setState(() => _currentSort = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppTheme.textDim,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDebtList() {
    final sortedList = _sortedDebts;
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (sortedList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppTheme.textDim.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('Здесь пока пусто', style: TextStyle(color: AppTheme.textDim)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final debt = sortedList[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          child: Dismissible(
            key: Key(debt.id),
            background: _viewDeleted 
                ? _buildDismissBackground(true, isRestore: true) // Восстановить
                : _buildDismissBackground(true), // Свайп вправо (Звонок)
            secondaryBackground: _buildDismissBackground(false), // Справо налево (Удаление)
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                if (_viewDeleted) {
                  // Восстановление
                  SupabaseService.updateDebt(debt.id, {'is_deleted': false}).catchError((_) {});
                  setState(() => _debts.remove(debt));
                  return true;
                } else {
                  // Звонок
                  if (debt.phoneNumber.isNotEmpty) {
                    final Uri launchUri = Uri(scheme: 'tel', path: debt.phoneNumber);
                    await launchUrl(launchUri);
                  }
                  return false; // Не удалять из списка
                }
              }
              return true; // Разрешить удаление (в корзину или насовсем)
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                if (_viewDeleted) {
                  // Удаление из корзины = полное удаление
                  SupabaseService.deleteDebt(debt.id).catchError((_) {});
                } else {
                  // Перемещение в корзину
                  SupabaseService.updateDebt(debt.id, {'is_deleted': true}).catchError((_) {});
                }
                setState(() => _debts.remove(debt));
              }
            },
            child: InkWell(
              onLongPress: () => _showEditDebtDialog(debt),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: debt.isPaid ? Colors.grey : AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        '${index + 1}', // Порядковый номер
                        style: TextStyle(
                          color: debt.isPaid ? Colors.white54 : AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.personName.isEmpty 
                                ? '' 
                                : debt.personName.split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' '), // Каждое слово с большой буквы
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (debt.phoneNumber.isNotEmpty)
                            Text(debt.phoneNumber, style: TextStyle(color: AppTheme.primary.withOpacity(0.7), fontSize: 13)),
                          if (debt.description.isNotEmpty)
                            Text(debt.description, style: const TextStyle(color: AppTheme.textDim, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${NumberFormat.simpleCurrency(locale: 'ru_RU', name: '').format(debt.amount)} с',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: debt.isPaid ? Colors.grey : AppTheme.primary,
                          ),
                        ),
                        Text(DateFormat('dd MMM').format(debt.date), style: const TextStyle(fontSize: 12, color: AppTheme.textDim)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDismissBackground(bool isLeftAction, {bool isRestore = false}) {
    Color bgColor = Colors.redAccent.withOpacity(0.8);
    IconData icon = Icons.delete_sweep;
    String label = 'Удалить';

    if (isLeftAction) {
      if (isRestore) {
        bgColor = Colors.blueAccent.withOpacity(0.8);
        icon = Icons.restore_from_trash;
        label = 'Восстановить';
      } else {
        bgColor = Colors.green.withOpacity(0.8);
        icon = Icons.phone_enabled;
        label = 'Позвонить';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: isLeftAction ? Alignment.centerLeft : Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLeftAction) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ] else ...[
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Icon(icon, color: Colors.white),
          ],
        ],
      ),
    );
  }

  void _showAddDebtDialog() {
    String name = '';
    String phone = '';
    double amount = 0;
    String desc = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Добавить должника', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(hintText: 'Имя должника'),
              onChanged: (v) => name = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Телефон'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => phone = v,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Сумма', prefixText: 'с '),
              keyboardType: TextInputType.number,
              onChanged: (v) => amount = double.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(hintText: 'Комментарий (необязательно)'),
              onChanged: (v) => desc = v,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (name.isNotEmpty && amount > 0) {
                  final newDebt = Debt(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: SupabaseService.currentUser?.id ?? 'demo',
                    personName: name,
                    phoneNumber: phone,
                    amount: amount,
                    description: desc,
                    date: DateTime.now(),
                    type: DebtType.owed,
                  );
                  SupabaseService.addDebt(newDebt).catchError((_) {});
                  setState(() => _debts.insert(0, newDebt));
                  Navigator.pop(context);
                }
              },
              child: const Text('Сохранить'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  double _parseMath(String input) {
    if (input.isEmpty) return 0;
    String clean = input.replaceAll(' ', '').replaceAll(',', '.');
    double total = 0;
    String current = "";
    String op = '+';
    for (int i = 0; i < clean.length; i++) {
      final c = clean[i];
      if (RegExp(r'[0-9.]').hasMatch(c)) {
        current += c;
      }
      if (c == '+' || c == '-' || i == clean.length - 1) {
        if (current.isNotEmpty) {
          final val = double.tryParse(current) ?? 0;
          if (op == '+') total += val;
          if (op == '-') total -= val;
          current = "";
        }
        op = c;
      }
    }
    return total;
  }

  void _showEditDebtDialog(Debt debt) {
    String name = debt.personName;
    String phone = debt.phoneNumber;
    String amountInput = debt.amount.toString();
    String desc = debt.description;

    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final amountController = TextEditingController(text: amountInput);
    final descController = TextEditingController(text: desc);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Редактировать', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Имя должника'),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(hintText: 'Телефон'),
                keyboardType: TextInputType.phone,
                onChanged: (v) => phone = v,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  hintText: 'Сумма',
                  prefixText: 'с ',
                  suffixText: _parseMath(amountController.text) != double.tryParse(amountController.text) 
                    ? '= ${_parseMath(amountController.text).toStringAsFixed(0)}' 
                    : '',
                ),
                keyboardType: TextInputType.text,
                onChanged: (v) => setModalState(() => amountInput = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(hintText: 'Комментарий (необязательно)'),
                onChanged: (v) => desc = v,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  double finalAmount = _parseMath(amountController.text);
                  if (name.isNotEmpty && finalAmount > 0) {
                    final updatedDebt = Debt(
                      id: debt.id,
                      userId: debt.userId,
                      personName: name,
                      phoneNumber: phone,
                      amount: finalAmount,
                      description: desc,
                      date: debt.date,
                      type: debt.type,
                      isPaid: debt.isPaid,
                    );
                    SupabaseService.updateDebt(debt.id, updatedDebt.toJson()).catchError((_) {});
                    setState(() {
                      final index = _debts.indexWhere((d) => d.id == debt.id);
                      if (index != -1) _debts[index] = updatedDebt;
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Сохранить изменения'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
