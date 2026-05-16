import 'package:flutter/material.dart';
import '../theme.dart';
import '../main.dart';

class AsadoConfigModal extends StatefulWidget {
  final JuntadaProvider provider;

  const AsadoConfigModal({super.key, required this.provider});

  @override
  State<AsadoConfigModal> createState() => _AsadoConfigModalState();
}

class _AsadoConfigModalState extends State<AsadoConfigModal> {
  late int _grams;
  late bool _chorizos;
  late bool _morcillas;
  late int _breads;
  late bool _tomato;
  late bool _lettuce;
  late bool _onion;
  late bool _russian;
  late bool _mayo;
  late bool _soda;

  @override
  void initState() {
    super.initState();
    _grams = widget.provider.meatGramsPerPerson;
    _chorizos = widget.provider.showChorizos;
    _morcillas = widget.provider.showMorcillas;
    _breads = widget.provider.breadsPerPerson;
    _tomato = widget.provider.showTomato;
    _lettuce = widget.provider.showLettuce;
    _onion = widget.provider.showOnion;
    _russian = widget.provider.showRussianSalad;
    _mayo = widget.provider.showMayonnaise;
    _soda = widget.provider.showSoda;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: JuntadaTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
            'Configuración de Asado',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Asado setting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Asado (grs por persona)',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _grams = (_grams - 50).clamp(100, 2000)),
                            icon: const Icon(Icons.remove_circle_outline, color: JuntadaTheme.accent),
                          ),
                          Text(
                            '$_grams g',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _grams = (_grams + 50).clamp(100, 2000)),
                            icon: const Icon(Icons.add_circle_outline, color: JuntadaTheme.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(color: Colors.white10, height: 32),
        
                  // Breads setting
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pan (miñones por persona)',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _breads = (_breads - 1).clamp(0, 20)),
                            icon: const Icon(Icons.remove_circle_outline, color: JuntadaTheme.accent),
                          ),
                          Text(
                            '$_breads',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _breads = (_breads + 1).clamp(0, 20)),
                            icon: const Icon(Icons.add_circle_outline, color: JuntadaTheme.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(color: Colors.white10, height: 32),
                  
                  // Chorizos setting
                  _buildSwitchRow('Chorizos (1 por persona)', _chorizos, (val) => setState(() => _chorizos = val)),
                  const Divider(color: Colors.white10, height: 32),
                  
                  // Morcillas setting
                  _buildSwitchRow('Morcillas (1 cada 2 personas)', _morcillas, (val) => setState(() => _morcillas = val)),
                  const Divider(color: Colors.white10, height: 32),

                  // Drinks Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Bebidas', style: TextStyle(color: JuntadaTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow('Gaseosa (1L por persona)', _soda, (val) => setState(() => _soda = val)),
                  const Divider(color: Colors.white10, height: 32),

                  // Salad Section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Ensalada', style: TextStyle(color: JuntadaTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow('Tomates', _tomato, (val) => setState(() => _tomato = val)),
                  _buildSwitchRow('Lechuga', _lettuce, (val) => setState(() => _lettuce = val)),
                  _buildSwitchRow('Cebolla', _onion, (val) => setState(() => _onion = val)),
                  _buildSwitchRow('Ensalada Rusa', _russian, (val) => setState(() => _russian = val)),
                  
                  if (_russian) 
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 8),
                      child: _buildSwitchRow('Incluir Mayonesa', _mayo, (val) => setState(() => _mayo = val)),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.provider.updateAsadoConfig(
                  grams: _grams, 
                  chorizos: _chorizos,
                  morcillas: _morcillas,
                  breads: _breads,
                  tomato: _tomato,
                  lettuce: _lettuce,
                  onion: _onion,
                  russian: _russian,
                  mayo: _mayo,
                  soda: _soda,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: JuntadaTheme.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Guardar configuración', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Switch(
            value: value,
            activeTrackColor: JuntadaTheme.secondary.withValues(alpha: 0.5),
            activeThumbColor: JuntadaTheme.secondary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
