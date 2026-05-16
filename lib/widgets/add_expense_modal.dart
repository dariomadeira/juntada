import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../main.dart';
import '../models.dart';
import 'master_diner_sheet.dart';

class AddExpenseModal extends StatefulWidget {
  final JuntadaProvider provider;
  final Function(String name, double amount, String description) onAdd;
  final Expense? initialExpense;

  const AddExpenseModal({
    super.key,
    required this.onAdd,
    required this.provider,
    this.initialExpense,
  });

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialExpense != null) {
      _nameController.text = widget.initialExpense!.userName;
      _amountController.text = NumberFormat.decimalPattern('es_AR').format(widget.initialExpense!.amount.toInt());
      _descController.text = widget.initialExpense!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _showSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MasterDinerSheet(
        provider: widget.provider,
        onSelected: (user) {
          setState(() {
            _nameController.text = user.name;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: JuntadaTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.initialExpense != null ? 'Editar gasto' : 'Nuevo gasto',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              label: 'Nombre',
              hint: '¿Quién gastó?',
              icon: Icons.person_outline_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              suggestions: widget.initialExpense != null ? null : widget.provider.users.map((u) => u.name).toList(),
              readOnly: widget.initialExpense != null,
              suffixIcon: widget.initialExpense != null 
                ? null 
                : IconButton(
                    onPressed: _showSelector,
                    icon: const Icon(Icons.group_add_outlined, color: JuntadaTheme.primary),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _amountController,
                    label: 'Monto',
                    hint: '0',
                    icon: Icons.attach_money_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _descController,
                    label: 'Descripción',
                    hint: '¿En qué?',
                    icon: Icons.description_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: JuntadaTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirmar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<String>? suggestions,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: JuntadaTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (suggestions != null && suggestions.isNotEmpty)
          RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: focusNode,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') return const Iterable<String>.empty();
              return suggestions.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              controller.text = selection;
            },
            fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
              return _buildBaseTextField(
                controller: fieldController,
                focusNode: focusNode,
                hint: hint,
                icon: icon,
                validator: validator,
                keyboardType: keyboardType,
                inputFormatters: inputFormatters,
                suffixIcon: suffixIcon,
                readOnly: readOnly,
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 8,
                  color: JuntadaTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 48,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: const TextStyle(color: Colors.white)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          )
        else
          _buildBaseTextField(
            controller: controller,
            hint: hint,
            icon: icon,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            suffixIcon: suffixIcon,
            readOnly: readOnly,
          ),
      ],
    );
  }

  Widget _buildBaseTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      style: TextStyle(color: readOnly ? Colors.white.withValues(alpha: 0.5) : Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        prefixIcon: Icon(icon, color: (readOnly ? JuntadaTheme.textSecondary : JuntadaTheme.primary).withValues(alpha: 0.5), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: readOnly ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cleanAmountText = _amountController.text.replaceAll('.', '');
      final amount = double.tryParse(cleanAmountText) ?? 0.0;
      widget.onAdd(
        _nameController.text.trim(),
        amount,
        _descController.text.trim(),
      );
      Navigator.pop(context);
    }
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('es_AR');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Limpiar cualquier carácter que no sea dígito
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int value = int.parse(cleanText);
    final String formattedText = _formatter.format(value);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
