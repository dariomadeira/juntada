import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models.dart';
import '../theme.dart';
import '../main.dart';
import 'add_diner_modal.dart';

class MasterDinerSheet extends StatefulWidget {
  final JuntadaProvider provider;
  final Function(User)? onSelected;

  const MasterDinerSheet({super.key, required this.provider, this.onSelected});

  @override
  State<MasterDinerSheet> createState() => _MasterDinerSheetState();
}

class _MasterDinerSheetState extends State<MasterDinerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final filteredMaster = widget.provider.masterDiners.where((u) {
          return u.name.toLowerCase().contains(_searchQuery);
        }).toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: JuntadaTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lista Maestra',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showAddNewToMaster(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: JuntadaTheme.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_rounded, color: JuntadaTheme.accent, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSearchBar(),
              Expanded(
                child: _buildMasterList(filteredMaster),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: JuntadaTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar en la lista maestra...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: const Icon(Icons.search_rounded, color: JuntadaTheme.textSecondary, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMasterList(List<User> users) {
    if (widget.provider.masterDiners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text(
              'No hay personas en la lista maestra',
              style: TextStyle(color: JuntadaTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _showAddNewToMaster(context),
              child: const Text('Agregar primera persona', style: TextStyle(color: JuntadaTheme.accent)),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text('No se encontraron resultados', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isAlreadyAdded = widget.provider.shoppingUsers.any((u) => u.id == user.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key('master-${user.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            ),
            onDismissed: (_) => widget.provider.removeMasterDiner(user.id),
            child: InkWell(
              onTap: () {
                if (widget.onSelected != null) {
                  widget.onSelected!(user);
                  Navigator.pop(context);
                } else if (!isAlreadyAdded) {
                  widget.provider.addShoppingUser(user);
                  Navigator.pop(context);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: JuntadaTheme.surface.withValues(alpha: isAlreadyAdded ? 0.2 : 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isAlreadyAdded 
                      ? Colors.transparent 
                      : Colors.white.withValues(alpha: 0.05)
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: (isAlreadyAdded ? JuntadaTheme.textSecondary : JuntadaTheme.accent).withValues(alpha: 0.1),
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: TextStyle(
                          color: isAlreadyAdded ? JuntadaTheme.textSecondary : JuntadaTheme.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          color: isAlreadyAdded ? JuntadaTheme.textSecondary : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isAlreadyAdded)
                      const Icon(Icons.check_circle_rounded, color: JuntadaTheme.secondary, size: 20)
                    else
                      Icon(Icons.add_circle_outline_rounded, color: Colors.white.withValues(alpha: 0.2), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).slideX(begin: 0.05);
      },
    );
  }

  void _showAddNewToMaster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddDinerModal(
        onAdd: (name) => widget.provider.addMasterDiner(name),
      ),
    );
  }
}
